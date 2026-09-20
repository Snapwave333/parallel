use crate::auth::{now, CurrentUser};
use crate::error::{ApiError, ApiResult};
use crate::state::AppState;
use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::extract::{Query, State};
use axum::response::Response;
use axum::routing::get;
use axum::{Json, Router};
use futures_util::{SinkExt, StreamExt};
use serde::Deserialize;
use serde_json::{json, Value};

pub struct ContractRule {
    pub key: &'static str,
    pub label: &'static str,
    pub ask_first: bool,
}

pub const CONTRACT_RULES: &[ContractRule] = &[
    ContractRule { key: "double_texting", label: "Double texting is fine", ask_first: false },
    ContractRule { key: "long_messages", label: "Long messages are welcome", ask_first: false },
    ContractRule { key: "memes", label: "Memes are welcome", ask_first: false },
    ContractRule { key: "direct_questions", label: "Questions can be direct", ask_first: false },
    ContractRule { key: "day_to_respond", label: "Taking a day to respond is fine", ask_first: false },
    ContractRule { key: "constant_conversation", label: "No expectation of constant conversation", ask_first: false },
    ContractRule { key: "talk_first", label: "Ask first before voice or video calls", ask_first: true },
];

pub const INTENT_SIGNALS: &[&str] =
    &["romantic", "more_time", "friendship", "unsure", "meet", "not_compatible"];

pub const STATUS_BATTERY_MAX: i64 = 4;
pub const STATUS_TEMPERATURES: &[&str] = &["chatty", "normal", "quiet", "low_energy", "space"];

fn is_member(a: i64, b: i64, user_id: i64) -> bool {
    a == user_id || b == user_id
}

async fn member_check(db: &sqlx::SqlitePool, conv_id: i64, user_id: i64) -> ApiResult<Option<(i64, i64)>> {
    let row: Option<(i64, i64)> = sqlx::query_as(
        "SELECT user_a, user_b FROM conversations WHERE id = ?",
    )
    .bind(conv_id)
    .fetch_optional(db)
    .await?;
    match row {
        Some((a, b)) if is_member(a, b, user_id) => Ok(Some((a, b))),
        Some(_) => Err(ApiError::forbidden("not a member of this conversation")),
        None => Ok(None),
    }
}

async fn list_conversations(
    State(state): State<AppState>,
    user: CurrentUser,
) -> ApiResult<Json<Value>> {
    let convs: Vec<(i64, i64, i64)> = sqlx::query_as(
        "SELECT id, user_a, user_b FROM conversations WHERE user_a = ? OR user_b = ? ORDER BY id DESC",
    )
    .bind(user.user_id)
    .bind(user.user_id)
    .fetch_all(&state.db)
    .await?;
    let mut out = Vec::new();
    for (id, a, b) in convs {
        let other = if a == user.user_id { b } else { a };
        let other_user = crate::auth::load_user(&state.db, other).await?;
        let last: Option<(i64, i64, String, i64)> = sqlx::query_as(
            "SELECT id, sender_id, body, created_at FROM messages WHERE conversation_id = ? ORDER BY id DESC LIMIT 1",
        )
        .bind(id)
        .fetch_optional(&state.db)
        .await?;
        out.push(json!({
            "id": id,
            "other_user": other_user.public(),
            "last_message": last.map(|(mid, sender, body, created)| json!({
                "id": mid, "sender_id": sender, "body": body, "created_at": created
            })),
        }));
    }
    Ok(Json(json!(out)))
}

#[derive(Deserialize)]
pub struct NewConversationReq {
    other_user_id: i64,
}

async fn create_conversation(
    State(state): State<AppState>,
    user: CurrentUser,
    Json(body): Json<NewConversationReq>,
) -> ApiResult<Json<Value>> {
    if body.other_user_id == user.user_id {
        return Err(ApiError::bad("cannot message yourself"));
    }
    crate::auth::load_user(&state.db, body.other_user_id).await?;
    let blocked: Option<(i64,)> = sqlx::query_as(
        "SELECT id FROM blocks WHERE (blocker_id = ? AND blocked_id = ?) OR (blocker_id = ? AND blocked_id = ?)",
    )
    .bind(user.user_id)
    .bind(body.other_user_id)
    .bind(body.other_user_id)
    .bind(user.user_id)
    .fetch_optional(&state.db)
    .await?;
    if blocked.is_some() {
        return Err(ApiError::forbidden("cannot start a conversation with this user"));
    }
    let id = crate::discovery::ensure_conversation(&state.db, user.user_id, body.other_user_id).await?;
    Ok(Json(json!({ "id": id, "ok": true })))
}

#[derive(Deserialize)]
pub struct MessagesQuery {
    after_id: Option<i64>,
}

async fn messages(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(conv_id): Path<i64>,
    Query(q): Query<MessagesQuery>,
) -> ApiResult<Json<Value>> {
    let conv_id_ok = member_check(&state.db, conv_id, user.user_id).await?;
    if conv_id_ok.is_none() {
        return Err(ApiError::not_found("conversation not found"));
    }
    let rows: Vec<(i64, i64, String, String, i64, i64)> = sqlx::query_as(
        "SELECT id, sender_id, body, kind, no_response_needed, created_at FROM messages WHERE conversation_id = ? AND id > ? ORDER BY id",
    )
    .bind(conv_id)
    .bind(q.after_id.unwrap_or(0))
    .fetch_all(&state.db)
    .await?;
    let list: Vec<Value> = rows
        .into_iter()
        .map(|(id, sender_id, body, kind, no_response_needed, created)| {
            json!({
                "id": id,
                "sender_id": sender_id,
                "body": body,
                "kind": kind,
                "no_response_needed": no_response_needed == 1,
                "state": if sender_id == user.user_id { "sent" } else { "delivered" },
                "created_at": created,
            })
        })
        .collect();
    Ok(Json(json!({ "conversation_id": conv_id, "messages": list })))
}

#[derive(Deserialize)]
pub struct SendMessageReq {
    body: String,
    kind: Option<String>,
    no_response_needed: Option<bool>,
}

async fn send_message(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(conv_id): Path<i64>,
    Json(body): Json<SendMessageReq>,
) -> ApiResult<Json<Value>> {
    member_check(&state.db, conv_id, user.user_id).await?
        .ok_or_else(|| ApiError::not_found("conversation not found"))?;
    let text = body.body.trim().to_string();
    if text.is_empty() {
        return Err(ApiError::bad("message body is required"));
    }
    if text.chars().count() > 6000 {
        return Err(ApiError::bad("message too long"));
    }
    let kind = body.kind.unwrap_or_else(|| "text".into());
    if !["text", "voice", "image", "system"].contains(&kind.as_str()) {
        return Err(ApiError::bad("invalid message kind"));
    }
    let ts = now();
    let (id,): (i64,) = sqlx::query_as(
        "INSERT INTO messages (conversation_id, sender_id, body, kind, no_response_needed, state, created_at) VALUES (?, ?, ?, ?, ?, 'sent', ?) RETURNING id",
    )
    .bind(conv_id)
    .bind(user.user_id)
    .bind(&text)
    .bind(&kind)
    .bind(if body.no_response_needed.unwrap_or(false) { 1 } else { 0 })
    .bind(ts)
    .fetch_one(&state.db)
    .await?;
    let event = json!({
        "type": "message",
        "message": {
            "id": id,
            "conversation_id": conv_id,
            "sender_id": user.user_id,
            "body": text,
            "kind": kind,
            "no_response_needed": body.no_response_needed.unwrap_or(false),
            "state": "sent",
            "created_at": ts,
        }
    });
    state.hub.publish(&format!("conv:{conv_id}"), &event.to_string());
    Ok(Json(event))
}

async fn contract(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(conv_id): Path<i64>,
) -> ApiResult<Json<Value>> {
    member_check(&state.db, conv_id, user.user_id).await?
        .ok_or_else(|| ApiError::not_found("conversation not found"))?;
    let set: std::collections::HashMap<String, i64> = sqlx::query_as::<_, (String, i64)>(
        "SELECT rule_key, value FROM conversation_contracts WHERE conversation_id = ?",
    )
    .bind(conv_id)
    .fetch_all(&state.db)
    .await?
    .into_iter()
    .map(|(k, v)| (k, v))
    .collect();
    let rules: Vec<Value> = CONTRACT_RULES
        .iter()
        .map(|r| {
            json!({
                "key": r.key,
                "label": r.label,
                "ask_first": r.ask_first,
                "enabled": set.get(r.key).copied().unwrap_or(0) == 1,
            })
        })
        .collect();
    Ok(Json(json!({ "conversation_id": conv_id, "rules": rules })))
}

#[derive(Deserialize)]
pub struct SetContractReq {
    rules: Vec<ContractIn>,
}

#[derive(Deserialize)]
pub struct ContractIn {
    key: String,
    enabled: bool,
}

async fn set_contract(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(conv_id): Path<i64>,
    Json(body): Json<SetContractReq>,
) -> ApiResult<Json<Value>> {
    member_check(&state.db, conv_id, user.user_id).await?
        .ok_or_else(|| ApiError::not_found("conversation not found"))?;
    for r in &body.rules {
        if !CONTRACT_RULES.iter().any(|c| c.key == r.key) {
            return Err(ApiError::bad(format!("unknown contract rule: {}", r.key)));
        }
        sqlx::query(
            "INSERT INTO conversation_contracts (conversation_id, rule_key, value) VALUES (?, ?, ?)
             ON CONFLICT(conversation_id, rule_key) DO UPDATE SET value = excluded.value",
        )
        .bind(conv_id)
        .bind(&r.key)
        .bind(if r.enabled { 1 } else { 0 })
        .execute(&state.db)
        .await?;
    }
    contract(State(state), user, Path(conv_id)).await
}

async fn contract_catalog() -> Json<Value> {
    Json(json!(CONTRACT_RULES
        .iter()
        .map(|r| json!({ "key": r.key, "label": r.label, "ask_first": r.ask_first }))
        .collect::<Vec<_>>()))
}

#[derive(Deserialize)]
pub struct IntentReq {
    signal: String,
}

async fn set_intent(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(other_id): Path<i64>,
    Json(body): Json<IntentReq>,
) -> ApiResult<Json<Value>> {
    if !INTENT_SIGNALS.contains(&body.signal.as_str()) {
        return Err(ApiError::bad("invalid intent signal"));
    }
    if other_id == user.user_id {
        return Err(ApiError::bad("cannot signal yourself"));
    }
    crate::auth::load_user(&state.db, other_id).await?;
    sqlx::query(
        "INSERT INTO intent_signals (user_id, other_id, signal, created_at) VALUES (?, ?, ?, ?)
         ON CONFLICT(user_id, other_id) DO UPDATE SET signal = excluded.signal, created_at = excluded.created_at",
    )
    .bind(user.user_id)
    .bind(other_id)
    .bind(&body.signal)
    .bind(now())
    .execute(&state.db)
    .await?;
    Ok(Json(json!({ "ok": true })))
}

async fn get_intent(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(other_id): Path<i64>,
) -> ApiResult<Json<Value>> {
    let mine: Option<(String,)> = sqlx::query_as(
        "SELECT signal FROM intent_signals WHERE user_id = ? AND other_id = ?",
    )
    .bind(user.user_id)
    .bind(other_id)
    .fetch_optional(&state.db)
    .await?;
    let theirs: Option<(String,)> = sqlx::query_as(
        "SELECT signal FROM intent_signals WHERE user_id = ? AND other_id = ?",
    )
    .bind(other_id)
    .bind(user.user_id)
    .fetch_optional(&state.db)
    .await?;
    let mine = mine.map(|(s,)| s);
    let theirs = theirs.map(|(s,)| s);
    let mutual = match (&mine, &theirs) {
        (Some(m), Some(t)) if m == t => Some(m.clone()),
        _ => None,
    };
    Ok(Json(json!({
        "mine": mine,
        "theirs_revealed": theirs.is_some(),
        "mutual": mutual,
    })))
}

async fn status_me(State(state): State<AppState>, user: CurrentUser) -> ApiResult<Json<Value>> {
    let row: Option<(i64, String)> = sqlx::query_as(
        "SELECT battery, temperature FROM social_status WHERE user_id = ?",
    )
    .bind(user.user_id)
    .fetch_optional(&state.db)
    .await?;
    match row {
        Some((battery, temperature)) => Ok(Json(json!({ "battery": battery, "temperature": temperature }))),
        None => Ok(Json(json!({ "battery": 3, "temperature": "normal" }))),
    }
}

#[derive(Deserialize)]
pub struct StatusReq {
    battery: Option<i64>,
    temperature: Option<String>,
}

async fn update_status(
    State(state): State<AppState>,
    user: CurrentUser,
    Json(body): Json<StatusReq>,
) -> ApiResult<Json<Value>> {
    let current = status_me(State(state.clone()), user.clone()).await?.0;
    let battery = match body.battery {
        Some(b) if (0..=STATUS_BATTERY_MAX).contains(&b) => b,
        Some(_) => return Err(ApiError::bad("battery must be 0..4")),
        None => current["battery"].as_i64().unwrap_or(3),
    };
    let temperature = match &body.temperature {
        Some(t) if STATUS_TEMPERATURES.contains(&t.as_str()) => t.clone(),
        Some(_) => return Err(ApiError::bad("invalid temperature")),
        None => current["temperature"].as_str().unwrap_or("normal").to_string(),
    };
    sqlx::query(
        "INSERT INTO social_status (user_id, battery, temperature, updated_at) VALUES (?, ?, ?, ?)
         ON CONFLICT(user_id) DO UPDATE SET battery = excluded.battery, temperature = excluded.temperature, updated_at = excluded.updated_at",
    )
    .bind(user.user_id)
    .bind(battery)
    .bind(&temperature)
    .bind(now())
    .execute(&state.db)
    .await?;
    status_me(State(state), user).await
}

async fn status_of(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(other_id): Path<i64>,
) -> ApiResult<Json<Value>> {
    let conv: Option<(i64, i64, i64)> = sqlx::query_as(
        "SELECT id, user_a, user_b FROM conversations WHERE (user_a = ? AND user_b = ?) OR (user_a = ? AND user_b = ?)",
    )
    .bind(user.user_id)
    .bind(other_id)
    .bind(other_id)
    .bind(user.user_id)
    .fetch_optional(&state.db)
    .await?;
    if conv.is_none() {
        return Err(ApiError::not_found("connection required to view status"));
    }
    let row = status_me(State(state), CurrentUser {
        user_id: other_id,
        email: String::new(),
        token: String::new(),
    })
    .await?;
    Ok(Json(row.0))
}

#[derive(Deserialize)]
pub struct WsChatQuery {
    token: String,
    conversation_id: i64,
}

async fn ws_chat(
    State(state): State<AppState>,
    Query(q): Query<WsChatQuery>,
    ws: WebSocketUpgrade,
) -> Response {
    ws.on_upgrade(move |socket| run_chat(socket, state, q))
}

async fn run_chat(socket: WebSocket, state: AppState, q: WsChatQuery) {
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
    let _members = match member_check(&state.db, q.conversation_id, user_id).await {
        Ok(Some(m)) => m,
        _ => return,
    };
    let room = format!("conv:{}", q.conversation_id);
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
        if let Message::Text(t) = msg {
            let _ = t;
        }
    }
    tx_handle.abort();
}

#[derive(Deserialize)]
pub struct ConversationPath {
    id: i64,
}

use axum::extract::Path;

async fn messages_path(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(conv): Path<ConversationPath>,
    Query(q): Query<MessagesQuery>,
) -> ApiResult<Json<Value>> {
    messages(State(state), user, Path(conv.id), Query(q)).await
}

async fn send_path(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(conv): Path<ConversationPath>,
    Json(body): Json<SendMessageReq>,
) -> ApiResult<Json<Value>> {
    send_message(State(state), user, Path(conv.id), Json(body)).await
}

async fn contract_path(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(conv): Path<ConversationPath>,
) -> ApiResult<Json<Value>> {
    contract(State(state), user, Path(conv.id)).await
}

async fn set_contract_path(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(conv): Path<ConversationPath>,
    Json(body): Json<SetContractReq>,
) -> ApiResult<Json<Value>> {
    set_contract(State(state), user, Path(conv.id), Json(body)).await
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/conversations", get(list_conversations).post(create_conversation))
        .route("/conversations/{id}/messages", get(messages_path).post(send_path))
        .route("/conversations/{id}/contract", get(contract_path).put(set_contract_path))
        .route("/contracts/catalog", get(contract_catalog))
        .route("/intent/{other_id}", get(get_intent).post(set_intent))
        .route("/status/me", get(status_me).put(update_status))
        .route("/status/{other_id}", get(status_of))
        .route("/ws/chat", get(ws_chat))
}