use crate::auth::{now, CurrentUser};
use crate::error::{ApiError, ApiResult};
use crate::state::AppState;
use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::extract::{Path, Query, State};
use axum::response::Response;
use axum::routing::get;
use axum::{Json, Router};
use futures_util::{SinkExt, StreamExt};
use serde::Deserialize;
use serde_json::{json, Value};

pub const SIGNAL_KEYS: &[&str] = &[
    "quiet",
    "break",
    "food_water",
    "less_stimulation",
    "change_activity",
    "reassurance",
    "talk_privately",
    "leave_soon",
    "go_home",
];

const CODE_CHARS: &[u8] = b"ABCDEFGHJKMNPQRSTUVWXYZ23456789";

fn new_pairing_code() -> String {
    let mut out = String::with_capacity(6);
    for _ in 0..6 {
        let i = (rand::random::<u32>() as usize) % CODE_CHARS.len();
        out.push(CODE_CHARS[i] as char);
    }
    out
}

async fn session_json(db: &sqlx::SqlitePool, s: &TogetherRow, viewer: i64) -> ApiResult<Value> {
    let other = if s.user_a == viewer { s.user_b } else { s.user_a };
    let user = crate::auth::load_user(db, other).await?;
    Ok(json!({
        "id": s.id,
        "pairing_code": s.pairing_code,
        "state": s.state,
        "permission_scope": s.permission_scope.as_deref().and_then(|p| serde_json::from_str::<Value>(p).ok()).unwrap_or(json!(null)),
        "created_at": s.created_at,
        "other_user": user.public(),
    }))
}

pub struct TogetherRow {
    pub id: i64,
    pub user_a: i64,
    pub user_b: i64,
    pub pairing_code: String,
    pub state: String,
    pub permission_scope: Option<String>,
    pub created_at: i64,
}

#[derive(Deserialize)]
pub struct NewSessionReq {
    partner_id: i64,
}

async fn new_session(
    State(state): State<AppState>,
    user: CurrentUser,
    Json(body): Json<NewSessionReq>,
) -> ApiResult<Json<Value>> {
    if body.partner_id == user.user_id {
        return Err(ApiError::bad("cannot start a together session with yourself"));
    }
    crate::auth::load_user(&state.db, body.partner_id).await?;
    let code = new_pairing_code();
    let ts = now();
    let scope = json!({
        "user_b": true,
        "emoji_reactions": true,
        "active_level": true,
        "social_status": true,
        "location_in_vicinity": true,
        "exit_button": true,
        "no_data_saved": true,
    })
    .to_string();
    let (id,): (i64,) = sqlx::query_as(
        "INSERT INTO together_sessions (user_a, user_b, pairing_code, permission_scope, state, created_at, expires_at) VALUES (?, ?, ?, ?, 'waiting', ?, ?) RETURNING id",
    )
    .bind(user.user_id)
    .bind(body.partner_id)
    .bind(&code)
    .bind(&scope)
    .bind(ts)
    .bind(ts + 6 * 3600)
    .fetch_one(&state.db)
    .await?;
    let row = fetch_session(&state.db, id).await?;
    Ok(Json(session_json(&state.db, &row, user.user_id).await?))
}

async fn fetch_session(db: &sqlx::SqlitePool, id: i64) -> ApiResult<TogetherRow> {
    fetch_session_opt(db, id)
        .await?
        .ok_or_else(|| ApiError::not_found("session not found"))
}

async fn fetch_session_opt(db: &sqlx::SqlitePool, id: i64) -> ApiResult<Option<TogetherRow>> {
    let row: Option<(i64, i64, i64, String, String, Option<String>, i64)> =
        sqlx::query_as("SELECT id, user_a, user_b, pairing_code, state, permission_scope, created_at FROM together_sessions WHERE id = ?")
            .bind(id)
            .fetch_optional(db)
            .await?;
    Ok(row.map(|(id, a, b, code, state, perm, ts)| TogetherRow {
        id,
        user_a: a,
        user_b: b,
        pairing_code: code,
        state,
        permission_scope: perm,
        created_at: ts,
    }))
}

#[derive(Deserialize)]
pub struct JoinReq {
    pairing_code: String,
}

async fn join(
    State(state): State<AppState>,
    user: CurrentUser,
    Json(body): Json<JoinReq>,
) -> ApiResult<Json<Value>> {
    let code = body.pairing_code.trim().to_uppercase();
    let s = match fetch_by_code(&state.db, &code).await? {
        Some(s) => s,
        None => return Err(ApiError::not_found("no session found for that code")),
    };
    if s.user_b != user.user_id {
        return Err(ApiError::forbidden("this session was not opened for you"));
    }
    if s.state != "waiting" {
        return Err(ApiError::conflict("session already joined or finished"));
    }
    sqlx::query("UPDATE together_sessions SET state = 'active' WHERE id = ?")
        .bind(s.id)
        .execute(&state.db)
        .await?;
    let s = fetch_session(&state.db, s.id).await?;
    state
        .hub
        .publish(&format!("tg:{}", s.id), &json!({ "type": "joined" }).to_string());
    Ok(Json(session_json(&state.db, &s, user.user_id).await?))
}

async fn fetch_by_code(db: &sqlx::SqlitePool, code: &str) -> ApiResult<Option<TogetherRow>> {
    let row: Option<(i64, i64, i64, String, String, Option<String>, i64)> =
        sqlx::query_as("SELECT id, user_a, user_b, pairing_code, state, permission_scope, created_at FROM together_sessions WHERE pairing_code = ?")
            .bind(code)
            .fetch_optional(db)
            .await?;
    Ok(row.map(|(id, a, b, code, state, perm, ts)| TogetherRow {
        id,
        user_a: a,
        user_b: b,
        pairing_code: code,
        state,
        permission_scope: perm,
        created_at: ts,
    }))
}

#[derive(Deserialize)]
pub struct SignalReq {
    signal: String,
}

async fn signal(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(id): Path<i64>,
    Json(body): Json<SignalReq>,
) -> ApiResult<Json<Value>> {
    let s = fetch_session(&state.db, id).await?;
    if s.user_a != user.user_id && s.user_b != user.user_id {
        return Err(ApiError::forbidden("not in this session"));
    }
    if !SIGNAL_KEYS.contains(&body.signal.as_str()) {
        return Err(ApiError::bad("invalid together signal"));
    }
    let ts = now();
    sqlx::query(
        "INSERT INTO together_signals (session_id, sender_id, signal_key, created_at) VALUES (?, ?, ?, ?)",
    )
    .bind(id)
    .bind(user.user_id)
    .bind(&body.signal)
    .bind(ts)
    .execute(&state.db)
    .await?;
    let event = json!({
        "type": "signal",
        "signal": body.signal,
        "user_id": user.user_id,
        "created_at": ts,
    });
    state.hub.publish(&format!("tg:{id}"), &event.to_string());
    Ok(Json(event))
}

async fn end(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(id): Path<i64>,
) -> ApiResult<Json<Value>> {
    let s = fetch_session(&state.db, id).await?;
    if s.user_a != user.user_id && s.user_b != user.user_id {
        return Err(ApiError::forbidden("not in this session"));
    }
    if s.state == "ended" {
        return Ok(Json(json!({ "ok": true })));
    }
    sqlx::query("UPDATE together_sessions SET state = 'ended' WHERE id = ?")
        .bind(id)
        .execute(&state.db)
        .await?;
    state
        .hub
        .publish(&format!("tg:{}", id), &json!({ "type": "ended" }).to_string());
    state.hub.drop_room(&format!("tg:{id}"));
    Ok(Json(json!({ "ok": true })))
}

async fn list_active(State(state): State<AppState>, user: CurrentUser) -> ApiResult<Json<Value>> {
    let ids: Vec<(i64,)> = sqlx::query_as(
        "SELECT id FROM together_sessions WHERE (user_a = ? OR user_b = ?) AND state IN ('waiting', 'active')",
    )
    .bind(user.user_id)
    .bind(user.user_id)
    .fetch_all(&state.db)
    .await?;
    let mut out = Vec::new();
    for (id,) in ids {
        let s = fetch_session(&state.db, id).await?;
        out.push(session_json(&state.db, &s, user.user_id).await?);
    }
    Ok(Json(json!({ "sessions": out })))
}

#[derive(Deserialize)]
pub struct WsTogetherQuery {
    token: String,
    session_id: i64,
}

async fn ws_together(
    State(state): State<AppState>,
    Query(q): Query<WsTogetherQuery>,
    ws: WebSocketUpgrade,
) -> Response {
    ws.on_upgrade(move |socket| run_together(socket, state, q))
}

async fn run_together(socket: WebSocket, state: AppState, q: WsTogetherQuery) {
    let session: Option<(i64,)> =
        sqlx::query_as("SELECT user_id FROM sessions WHERE token = ? AND revoked = 0 AND expires_at > ?")
            .bind(&q.token)
            .bind(now())
            .fetch_optional(&state.db)
            .await
            .ok()
            .flatten();
    let user_id = match session {
        Some((id,)) => id,
        None => return,
    };
    let ok = match fetch_session_opt(&state.db, q.session_id).await {
        Ok(Some(s)) => s.user_a == user_id || s.user_b == user_id,
        _ => false,
    };
    if !ok {
        return;
    }
    let room = format!("tg:{}", q.session_id);
    let mut rx = state.hub.join(&room);
    let (mut tx, mut rx_in) = socket.split();
    let tx_handle = tokio::spawn(async move {
        while let Ok(msg) = rx.recv().await {
            if tx.send(Message::Text(msg.into())).await.is_err() {
                break;
            }
        }
    });
    while let Some(Ok(msg)) = rx_in.next().await {
        if let Message::Text(_) = msg {
        }
    }
    tx_handle.abort();
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/sessions", get(list_active).post(new_session))
        .route("/join", axum::routing::post(join))
        .route("/sessions/{id}/signal", axum::routing::post(signal))
        .route("/sessions/{id}/end", axum::routing::post(end))
        .route("/ws/session", get(ws_together))
}