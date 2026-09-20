use crate::auth::{load_user, now, CurrentUser};
use crate::compat::{feature_rows, FeatureValue};
use crate::error::{ApiError, ApiResult};
use crate::state::AppState;
use axum::extract::{Path, State};
use axum::routing::{delete, get, post};
use axum::{Json, Router};
use serde::Deserialize;
use serde_json::{json, Value};

#[derive(serde::Serialize)]
struct Photo {
    id: i64,
    url: String,
    position: i64,
}

async fn my_photos(db: &sqlx::SqlitePool, user_id: i64) -> ApiResult<Vec<Photo>> {
    let rows: Vec<(i64, String, i64)> = sqlx::query_as(
        "SELECT id, url, position FROM profile_photos WHERE user_id = ? ORDER BY position, id",
    )
    .bind(user_id)
    .fetch_all(db)
    .await?;
    Ok(rows
        .into_iter()
        .map(|(id, url, position)| Photo { id, url, position })
        .collect())
}

async fn my_profile(State(state): State<AppState>, user: CurrentUser) -> ApiResult<Json<Value>> {
    let row = load_user(&state.db, user.user_id).await?;
    let photos = my_photos(&state.db, user.user_id).await?;
    let features = feature_rows(&state.db, user.user_id).await?;
    let interests: Vec<String> =
        sqlx::query_as("SELECT path FROM interests WHERE user_id = ? ORDER BY id")
            .bind(user.user_id)
            .fetch_all(&state.db)
            .await?
            .into_iter()
            .map(|(p,): (String,)| p)
            .collect();
    Ok(Json(json!({
        "user": row.public(),
        "photos": photos.iter().map(|p| json!({"id": p.id, "url": p.url, "position": p.position})).collect::<Vec<_>>(),
        "features": features.iter().map(|f| json!({
            "key": f.key, "value": f.value, "importance": f.importance,
            "classification": f.classification, "visibility": f.visibility,
        })).collect::<Vec<_>>(),
        "interests": interests,
        "discovery_enabled": row.discovery_enabled == 1,
    })))
}

#[derive(Deserialize)]
pub struct UpdateProfileReq {
    name: Option<String>,
    age: Option<i64>,
    gender: Option<String>,
    dating_intents: Option<Vec<String>>,
    relationship_goals: Option<Vec<String>>,
    city: Option<String>,
    about: Option<String>,
    discovery_enabled: Option<bool>,
}

async fn update_profile(
    State(state): State<AppState>,
    user: CurrentUser,
    Json(body): Json<UpdateProfileReq>,
) -> ApiResult<Json<Value>> {
    let current = load_user(&state.db, user.user_id).await?;
    if let Some(age) = body.age {
        if !(18..=120).contains(&age) {
            return Err(ApiError::bad("age must be between 18 and 120"));
        }
    }
    let to_json =
        |items: &Option<Vec<String>>| -> Option<String> {
            items
                .as_ref()
                .map(|v| serde_json::to_string(v).unwrap_or_else(|_| "[]".into()))
        };
    sqlx::query(
        "UPDATE users SET name = ?, age = ?, gender = ?, dating_intents = ?, relationship_goals = ?, city = ?, about = ?, discovery_enabled = ?, updated_at = ? WHERE id = ?",
    )
    .bind(body.name.or(current.name))
    .bind(body.age.or(current.age))
    .bind(body.gender.or(current.gender))
    .bind(to_json(&body.dating_intents).or_else(|| current.dating_intents.clone()))
    .bind(to_json(&body.relationship_goals).or_else(|| current.relationship_goals.clone()))
    .bind(body.city.or(current.city))
    .bind(body.about.or(current.about))
    .bind(body.discovery_enabled.map(|b| if b { 1 } else { 0 }).unwrap_or(current.discovery_enabled))
    .bind(now())
    .bind(user.user_id)
    .execute(&state.db)
    .await?;
    my_profile(State(state), user).await
}

#[derive(Deserialize)]
struct AddPhotoReq {
    url: String,
}

async fn add_photo(
    State(state): State<AppState>,
    user: CurrentUser,
    Json(body): Json<AddPhotoReq>,
) -> ApiResult<Json<Value>> {
    if body.url.is_empty() {
        return Err(ApiError::bad("photo url is required"));
    }
    let max: (i64,) = sqlx::query_as(
        "SELECT COALESCE(MAX(position), -1) FROM profile_photos WHERE user_id = ?",
    )
    .bind(user.user_id)
    .fetch_one(&state.db)
    .await?;
    let position = max.0 + 1;
    let (id,): (i64,) = sqlx::query_as(
        "INSERT INTO profile_photos (user_id, url, position, created_at) VALUES (?, ?, ?, ?) RETURNING id",
    )
    .bind(user.user_id)
    .bind(&body.url)
    .bind(position)
    .bind(now())
    .fetch_one(&state.db)
    .await?;
    Ok(Json(json!({ "id": id, "url": body.url, "position": position })))
}

async fn delete_photo(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(id): Path<i64>,
) -> ApiResult<Json<Value>> {
    let res = sqlx::query("DELETE FROM profile_photos WHERE id = ? AND user_id = ?")
        .bind(id)
        .bind(user.user_id)
        .execute(&state.db)
        .await?;
    if res.rows_affected() == 0 {
        return Err(ApiError::not_found("photo not found"));
    }
    Ok(Json(json!({ "ok": true })))
}

pub async fn public_profile(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> ApiResult<Json<Value>> {
    let row = load_user(&state.db, id).await?;
    let photos = my_photos(&state.db, id).await?;
    let features = feature_rows(&state.db, id).await?;
    let public_features: Vec<FeatureValue> = features
        .into_iter()
        .filter(|f| f.visibility == "public" || f.visibility == "mutual")
        .collect();
    let interests: Vec<String> =
        sqlx::query_as("SELECT path FROM interests WHERE user_id = ? ORDER BY id")
            .bind(id)
            .fetch_all(&state.db)
            .await?
            .into_iter()
            .map(|(p,): (String,)| p)
            .collect();
    Ok(Json(json!({
        "user": row.public(),
        "photos": photos.iter().map(|p| json!({"id": p.id, "url": p.url, "position": p.position})).collect::<Vec<_>>(),
        "features": public_features.iter().map(|f| json!({
            "key": f.key, "value": f.value, "importance": f.importance,
            "classification": f.classification, "visibility": f.visibility,
        })).collect::<Vec<_>>(),
        "interests": interests,
    })))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/me", get(my_profile).patch(update_profile))
        .route("/photos", post(add_photo))
        .route("/photos/{id}", delete(delete_photo))
}