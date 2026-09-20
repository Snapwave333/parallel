use crate::auth::{load_user, now, today, CurrentUser};
use crate::compat::{compare, feature_rows, interests_for, FeatureValue};
use crate::error::{ApiError, ApiResult};
use crate::state::AppState;
use axum::extract::{Path, State};
use axum::routing::get;
use axum::{Json, Router};
use serde::Deserialize;
use serde_json::{json, Value};

const DAILY_LIMIT: usize = 5;

pub async fn ensure_connection(db: &sqlx::SqlitePool, a: i64, b: i64) -> ApiResult<()> {
    sqlx::query(
        "INSERT OR IGNORE INTO connections (user_a, user_b, created_at) VALUES (min(?, ?), max(?, ?), ?)",
    )
    .bind(a)
    .bind(b)
    .bind(a)
    .bind(b)
    .bind(now())
    .execute(db)
    .await?;
    Ok(())
}

pub async fn ensure_conversation(db: &sqlx::SqlitePool, a: i64, b: i64) -> ApiResult<i64> {
    let existing: Option<(i64,)> =
        sqlx::query_as("SELECT id FROM conversations WHERE user_a = min(?, ?) AND user_b = max(?, ?)")
            .bind(a)
            .bind(b)
            .bind(a)
            .bind(b)
            .fetch_optional(db)
            .await?;
    if let Some((id,)) = existing {
        return Ok(id);
    }
    let (id,): (i64,) = sqlx::query_as(
        "INSERT INTO conversations (user_a, user_b, created_at) VALUES (min(?, ?), max(?, ?), ?) RETURNING id",
    )
    .bind(a)
    .bind(b)
    .bind(a)
    .bind(b)
    .bind(now())
    .fetch_one(db)
    .await?;
    Ok(id)
}

async fn my_city(db: &sqlx::SqlitePool, user_id: i64) -> ApiResult<Option<String>> {
    let (city,): (Option<String>,) =
        sqlx::query_as("SELECT city FROM users WHERE id = ?")
            .bind(user_id)
            .fetch_one(db)
            .await?;
    Ok(city)
}

async fn candidate_ids(
    db: &sqlx::SqlitePool,
    me: i64,
    my_city: &Option<String>,
) -> ApiResult<Vec<i64>> {
    let rows: Vec<(i64,)> = sqlx::query_as(
        "SELECT u.id FROM users u
         WHERE u.id != ?
           AND u.discovery_enabled = 1
           AND COALESCE(u.age, 18) >= 18
           AND (u.city IS NULL OR ? IS NULL OR u.city = ?)
           AND NOT EXISTS (SELECT 1 FROM blocks b WHERE (b.blocker_id = u.id AND b.blocked_id = ?) OR (b.blocker_id = ? AND b.blocked_id = u.id))
           AND NOT EXISTS (SELECT 1 FROM introductions i WHERE i.for_user = ? AND i.from_user = u.id)",
    )
    .bind(me)
    .bind(my_city)
    .bind(my_city)
    .bind(me)
    .bind(me)
    .bind(me)
    .fetch_all(db)
    .await?;
    Ok(rows.into_iter().map(|(id,)| id).collect())
}

async fn features_for(db: &sqlx::SqlitePool, user_id: i64) -> ApiResult<Vec<FeatureValue>> {
    feature_rows(db, user_id).await
}

fn score_candidate(
    mine: &[FeatureValue],
    mine_i: &[String],
    theirs: &[FeatureValue],
    their_i: &[String],
) -> Option<(f32, Value)> {
    let report = compare(mine, theirs, mine_i, their_i);
    if !report.dealbreaker_conflicts.is_empty() {
        return None;
    }
    let filled: Vec<f32> = report
        .dimensions
        .iter()
        .filter_map(|d| {
            d.compat
                .filter(|_| d.importance > 0)
        })
        .collect();
    let score = if filled.is_empty() {
        0.0
    } else {
        filled.iter().sum::<f32>() / filled.len() as f32
    };
    let explain: Vec<Value> = report
        .explain
        .into_iter()
        .filter(|e| e.level != "unknown")
        .take(6)
        .map(|e| json!({ "level": e.level, "text": e.text }))
        .collect();
    let reason = json!({
        "explain": explain,
        "shared_interests": report.shared_interests.len(),
        "overall": (score * 100.0).round(),
    });
    Some((score, reason))
}

async fn build_today(
    db: &sqlx::SqlitePool,
    me: i64,
    day: i64,
) -> ApiResult<Vec<(i64, String)>> {
    let mine = features_for(db, me).await?;
    let mine_i = interests_for(db, me).await?;
    let city = my_city(db, me).await?;
    let candidates = candidate_ids(db, me, &city).await?;

    let mut scored: Vec<(f32, i64, String)> = Vec::new();
    for id in candidates {
        let theirs = features_for(db, id).await?;
        let their_i = interests_for(db, id).await?;
        if let Some((score, reason)) = score_candidate(&mine, &mine_i, &theirs, &their_i) {
            scored.push((score, id, reason.to_string()));
        }
    }
    scored.sort_by(|a, b| b.0.partial_cmp(&a.0).unwrap_or(std::cmp::Ordering::Equal));
    scored.truncate(DAILY_LIMIT);

    let ts = now();
    for (_, id, reason) in &scored {
        sqlx::query(
            "INSERT OR IGNORE INTO introductions (for_user, from_user, reason, day, status, created_at) VALUES (?, ?, ?, ?, 'new', ?)",
        )
        .bind(me)
        .bind(id)
        .bind(reason)
        .bind(day)
        .bind(ts)
        .execute(db)
        .await?;
    }
    Ok(scored.into_iter().map(|(_, id, reason)| (id, reason)).collect())
}

async fn stored_today(db: &sqlx::SqlitePool, me: i64, day: i64) -> ApiResult<Vec<(i64, String)>> {
    let rows: Vec<(i64, String)> = sqlx::query_as(
        "SELECT from_user, reason FROM introductions WHERE for_user = ? AND day = ? ORDER BY status = 'new' DESC, created_at",
    )
    .bind(me)
    .bind(day)
    .fetch_all(db)
    .await?;
    Ok(rows)
}

async fn today_list(
    State(state): State<AppState>,
    user: CurrentUser,
) -> ApiResult<Json<Value>> {
    let day = today();
    let stored = stored_today(&state.db, user.user_id, day).await?;
    let list = if stored.is_empty() {
        build_today(&state.db, user.user_id, day).await?
    } else {
        stored
    };
    let mut out = Vec::new();
    for (id, reason) in list {
        let u = load_user(&state.db, id).await?;
        let pubs: Vec<Value> = profile_photos(&state.db, id).await?;
        out.push(json!({
            "user_id": id,
            "user": u.public(),
            "photos": pubs,
            "reason": serde_json::from_str::<Value>(&reason).unwrap_or(json!(null)),
        }));
    }
    Ok(Json(json!({ "count": out.len(), "day": day, "introductions": out })))
}

async fn profile_photos(db: &sqlx::SqlitePool, user_id: i64) -> ApiResult<Vec<Value>> {
    let rows: Vec<(i64, String, i64)> = sqlx::query_as(
        "SELECT id, url, position FROM profile_photos WHERE user_id = ? ORDER BY position, id",
    )
    .bind(user_id)
    .fetch_all(db)
    .await?;
    Ok(rows
        .into_iter()
        .map(|(id, url, position)| json!({ "id": id, "url": url, "position": position }))
        .collect())
}

#[derive(Deserialize)]
pub struct IntroduceReq {
    to_user: i64,
    reason: Option<String>,
}

async fn introduce(
    State(state): State<AppState>,
    user: CurrentUser,
    Json(body): Json<IntroduceReq>,
) -> ApiResult<Json<Value>> {
    if body.to_user == user.user_id {
        return Err(ApiError::bad("cannot introduce yourself"));
    }
    load_user(&state.db, body.to_user).await?;
    let reverse: Option<(i64,)> = sqlx::query_as(
        "SELECT id FROM introduction_requests WHERE from_user = ? AND to_user = ? AND status = 'pending'",
    )
    .bind(body.to_user)
    .bind(user.user_id)
    .fetch_optional(&state.db)
    .await?;

    let ts = now();
    if let Some((rid,)) = reverse {
        sqlx::query("UPDATE introduction_requests SET status = 'accepted' WHERE id = ?")
            .bind(rid)
            .execute(&state.db)
            .await?;
        ensure_connection(&state.db, user.user_id, body.to_user).await?;
        let conversation_id = ensure_conversation(&state.db, user.user_id, body.to_user).await?;
        sqlx::query("UPDATE introductions SET status = 'introduced' WHERE for_user = ? AND from_user = ?")
            .bind(user.user_id)
            .bind(body.to_user)
            .execute(&state.db)
            .await?;
        return Ok(Json(json!({
            "matched": true,
            "conversation_id": conversation_id,
            "message": "You both wanted an introduction.",
        })));
    }

    sqlx::query(
        "INSERT INTO introduction_requests (from_user, to_user, reason, status, created_at) VALUES (?, ?, ?, 'pending', ?)",
    )
    .bind(user.user_id)
    .bind(body.to_user)
    .bind(&body.reason)
    .bind(ts)
    .execute(&state.db)
    .await?;
    sqlx::query("UPDATE introductions SET status = 'introduced' WHERE for_user = ? AND from_user = ?")
        .bind(user.user_id)
        .bind(body.to_user)
        .execute(&state.db)
        .await?;
    Ok(Json(json!({ "matched": false, "message": "Introduction sent." })))
}

async fn request_list(
    db: &sqlx::SqlitePool,
    me: i64,
    incoming: bool,
) -> ApiResult<Vec<Value>> {
    let sql = if incoming {
        "SELECT id, from_user, to_user, reason, status, created_at FROM introduction_requests WHERE to_user = ? ORDER BY created_at DESC"
    } else {
        "SELECT id, from_user, to_user, reason, status, created_at FROM introduction_requests WHERE from_user = ? ORDER BY created_at DESC"
    };
    let rows: Vec<(i64, i64, i64, Option<String>, String, i64)> =
        sqlx::query_as(sql).bind(me).fetch_all(db).await?;
    let mut out = Vec::new();
    for (id, from, to, reason, status, created) in rows {
        let other = if incoming { from } else { to };
        let u = load_user(db, other).await?;
        out.push(json!({
            "id": id,
            "from_user": from,
            "to_user": to,
            "other_user": u.public(),
            "reason": reason,
            "status": status,
            "created_at": created,
        }));
    }
    Ok(out)
}

async fn incoming(State(state): State<AppState>, user: CurrentUser) -> ApiResult<Json<Value>> {
    Ok(Json(json!(request_list(&state.db, user.user_id, true).await?)))
}

async fn outgoing(State(state): State<AppState>, user: CurrentUser) -> ApiResult<Json<Value>> {
    Ok(Json(json!(request_list(&state.db, user.user_id, false).await?)))
}

async fn accept_request(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(id): Path<i64>,
) -> ApiResult<Json<Value>> {
    let req: Option<(i64, i64, String)> =
        sqlx::query_as("SELECT from_user, to_user, status FROM introduction_requests WHERE id = ?")
            .bind(id)
            .fetch_optional(&state.db)
            .await?;
    let (from, to, status) = req.ok_or_else(|| ApiError::not_found("request not found"))?;
    if to != user.user_id {
        return Err(ApiError::forbidden("this request is not addressed to you"));
    }
    if status != "pending" {
        return Err(ApiError::conflict("request already handled"));
    }
    sqlx::query("UPDATE introduction_requests SET status = 'accepted' WHERE id = ?")
        .bind(id)
        .execute(&state.db)
        .await?;
    ensure_connection(&state.db, from, to).await?;
    let conversation_id = ensure_conversation(&state.db, from, to).await?;
    Ok(Json(json!({ "ok": true, "conversation_id": conversation_id })))
}

async fn decline_request(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(id): Path<i64>,
) -> ApiResult<Json<Value>> {
    let req: Option<(i64, i64, String)> =
        sqlx::query_as("SELECT from_user, to_user, status FROM introduction_requests WHERE id = ?")
            .bind(id)
            .fetch_optional(&state.db)
            .await?;
    let (_from, to, status) = req.ok_or_else(|| ApiError::not_found("request not found"))?;
    if to != user.user_id {
        return Err(ApiError::forbidden("this request is not addressed to you"));
    }
    if status != "pending" {
        return Err(ApiError::conflict("request already handled"));
    }
    sqlx::query("UPDATE introduction_requests SET status = 'declined' WHERE id = ?")
        .bind(id)
        .execute(&state.db)
        .await?;
    Ok(Json(json!({ "ok": true })))
}

async fn connections(State(state): State<AppState>, user: CurrentUser) -> ApiResult<Json<Value>> {
    let rows: Vec<(i64, i64)> = sqlx::query_as(
        "SELECT user_a, user_b FROM connections WHERE user_a = ? OR user_b = ?",
    )
    .bind(user.user_id)
    .bind(user.user_id)
    .fetch_all(&state.db)
    .await?;
    let mut out = Vec::new();
    for (a, b) in rows {
        let other = if a == user.user_id { b } else { a };
        let u = load_user(&state.db, other).await?;
        out.push(json!({ "user_id": other, "user": u.public(), "since": now() }));
    }
    Ok(Json(json!(out)))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/today", get(today_list))
        .route("/introduce", axum::routing::post(introduce))
        .route("/requests/incoming", get(incoming))
        .route("/requests/outgoing", get(outgoing))
        .route(
            "/requests/{id}/accept",
            axum::routing::post(accept_request),
        )
        .route(
            "/requests/{id}/decline",
            axum::routing::post(decline_request),
        )
        .route("/connections", get(connections))
}