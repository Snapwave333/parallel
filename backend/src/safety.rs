use crate::auth::{now, CurrentUser};
use crate::error::{ApiError, ApiResult};
use crate::state::AppState;
use axum::extract::{Path, State};
use axum::routing::get;
use axum::{Json, Router};
use serde::Deserialize;
use serde_json::{json, Value};

pub const REPORT_CATEGORIES: &[&str] = &[
    "harassment",
    "unwanted_messages",
    "explicit_content",
    "impersonation",
    "underage",
    "other",
];

async fn blocked_list(State(state): State<AppState>, user: CurrentUser) -> ApiResult<Json<Value>> {
    let ids: Vec<(i64, i64)> = sqlx::query_as(
        "SELECT blocked_id, created_at FROM blocks WHERE blocker_id = ?",
    )
    .bind(user.user_id)
    .fetch_all(&state.db)
    .await?;
    let mut out = Vec::new();
    for (id, ts) in ids {
        let u = crate::auth::load_user(&state.db, id).await?;
        out.push(json!({ "blocked_id": id, "user": u.public(), "created_at": ts }));
    }
    Ok(Json(json!(out)))
}

#[derive(Deserialize)]
pub struct BlockReq {
    user_id: i64,
}

async fn block(
    State(state): State<AppState>,
    user: CurrentUser,
    Json(body): Json<BlockReq>,
) -> ApiResult<Json<Value>> {
    if body.user_id == user.user_id {
        return Err(ApiError::bad("cannot block yourself"));
    }
    crate::auth::load_user(&state.db, body.user_id).await?;
    sqlx::query("INSERT OR IGNORE INTO blocks (blocker_id, blocked_id, created_at) VALUES (?, ?, ?)")
        .bind(user.user_id)
        .bind(body.user_id)
        .bind(now())
        .execute(&state.db)
        .await?;
    Ok(Json(json!({ "ok": true })))
}

async fn unblock(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(id): Path<i64>,
) -> ApiResult<Json<Value>> {
    sqlx::query("DELETE FROM blocks WHERE blocker_id = ? AND blocked_id = ?")
        .bind(user.user_id)
        .bind(id)
        .execute(&state.db)
        .await?;
    Ok(Json(json!({ "ok": true })))
}

#[derive(Deserialize)]
pub struct ReportReq {
    user_id: i64,
    category: Option<String>,
    reason: Option<String>,
}

async fn report(
    State(state): State<AppState>,
    user: CurrentUser,
    Json(body): Json<ReportReq>,
) -> ApiResult<Json<Value>> {
    if body.user_id == user.user_id {
        return Err(ApiError::bad("cannot report yourself"));
    }
    crate::auth::load_user(&state.db, body.user_id).await?;
    if let Some(cat) = &body.category {
        if !REPORT_CATEGORIES.contains(&cat.as_str()) {
            return Err(ApiError::bad("invalid report category"));
        }
    }
    let category = body.category.unwrap_or_else(|| "other".to_string());
    sqlx::query(
        "INSERT INTO reports (reporter_id, reported_id, category, detail, created_at) VALUES (?, ?, ?, ?, ?)",
    )
    .bind(user.user_id)
    .bind(body.user_id)
    .bind(&category)
    .bind(&body.reason)
    .bind(now())
    .execute(&state.db)
    .await?;
    Ok(Json(json!({ "ok": true, "message": "Thanks. Our team looks into this and you are never shown to this person again." })))
}

async fn my_reports(State(state): State<AppState>, user: CurrentUser) -> ApiResult<Json<Value>> {
    let rows: Vec<(i64, i64, String, Option<String>, i64)> = sqlx::query_as(
        "SELECT id, reported_id, category, detail, created_at FROM reports WHERE reporter_id = ? ORDER BY id DESC",
    )
    .bind(user.user_id)
    .fetch_all(&state.db)
    .await?;
    let out: Vec<Value> = rows
        .into_iter()
        .map(|(id, reported, category, reason, ts)| {
            json!({ "id": id, "reported_id": reported, "category": category, "reason": reason, "created_at": ts })
        })
        .collect();
    Ok(Json(json!(out)))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/blocks", get(blocked_list).post(block))
        .route("/blocks/{id}", axum::routing::delete(unblock))
        .route("/reports", get(my_reports).post(report))
}