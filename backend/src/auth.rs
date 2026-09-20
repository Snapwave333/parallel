use crate::error::{ApiError, ApiResult};
use crate::state::AppState;
use argon2::password_hash::rand_core::OsRng;
use argon2::password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString};
use argon2::Argon2;
use axum::extract::{FromRequestParts, State};
use axum::http::header::AUTHORIZATION;
use axum::http::request::Parts;
use axum::routing::{get, post};
use axum::{Json, Router};
use rand::RngCore;
use serde::Deserialize;
use serde_json::json;
use sqlx::FromRow;
use std::time::{SystemTime, UNIX_EPOCH};

pub fn now() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0)
}

pub fn today() -> i64 {
    now() / 86400
}

pub fn parse_list(s: &Option<String>) -> Vec<String> {
    s.as_ref()
        .and_then(|v| serde_json::from_str::<Vec<String>>(v).ok())
        .unwrap_or_default()
}



#[derive(FromRow, Clone)]
pub struct UserRow {
    pub id: i64,
    pub email: String,
    pub password_hash: String,
    pub name: Option<String>,
    pub age: Option<i64>,
    pub gender: Option<String>,
    pub dating_intents: Option<String>,
    pub relationship_goals: Option<String>,
    pub city: Option<String>,
    pub about: Option<String>,
    pub age_verified: i64,
    pub identity_verified: i64,
    pub discovery_enabled: i64,
    pub created_at: i64,
    pub updated_at: i64,
}

impl UserRow {
    pub fn public(&self) -> serde_json::Value {
        json!({
            "id": self.id,
            "name": self.name,
            "age": self.age,
            "gender": self.gender,
            "city": self.city,
            "about": self.about,
            "dating_intents": parse_list(&self.dating_intents),
            "relationship_goals": parse_list(&self.relationship_goals),
            "age_verified": self.age_verified == 1,
            "identity_verified": self.identity_verified == 1,
        })
    }
}

pub async fn load_user(db: &sqlx::SqlitePool, id: i64) -> ApiResult<UserRow> {
    sqlx::query_as::<_, UserRow>("SELECT * FROM users WHERE id = ?")
        .bind(id)
        .fetch_optional(db)
        .await?
        .ok_or_else(|| ApiError::not_found("user not found"))
}

#[derive(FromRow)]
struct SessionRow {
    user_id: i64,
    expires_at: i64,
    revoked: i64,
}

pub fn hash_password(pw: &str) -> ApiResult<String> {
    let salt = SaltString::generate(&mut OsRng);
    Argon2::default()
        .hash_password(pw.as_bytes(), &salt)
        .map(|h| h.to_string())
        .map_err(|e| ApiError::internal(format!("hashing failed: {e}")))
}

fn verify_password(pw: &str, hash: &str) -> bool {
    PasswordHash::new(hash)
        .map(|p| Argon2::default().verify_password(pw.as_bytes(), &p).is_ok())
        .unwrap_or(false)
}

fn new_token() -> String {
    let mut b = [0u8; 32];
    rand::thread_rng().fill_bytes(&mut b);
    hex::encode(b)
}

const SESSION_TTL_SECS: i64 = 60 * 60 * 24 * 14;

#[derive(Clone)]
pub struct CurrentUser {
    pub user_id: i64,
    pub email: String,
    pub token: String,
}

impl FromRequestParts<AppState> for CurrentUser {
    type Rejection = ApiError;

    async fn from_request_parts(
        parts: &mut Parts,
        state: &AppState,
    ) -> Result<Self, Self::Rejection> {
        let header = parts
            .headers
            .get(AUTHORIZATION)
            .and_then(|v| v.to_str().ok())
            .and_then(|v| v.strip_prefix("Bearer "));
        let token = header
            .map(|s| s.to_string())
            .ok_or_else(|| ApiError::unauthorized("missing bearer token"))?;
        let s: Option<SessionRow> =
            sqlx::query_as("SELECT user_id, expires_at, revoked FROM sessions WHERE token = ?")
                .bind(&token)
                .fetch_optional(&state.db)
                .await?;
        let s = s
            .filter(|s| s.revoked == 0 && s.expires_at > now())
            .ok_or_else(|| ApiError::unauthorized("invalid or expired session"))?;
        let email: Option<(String,)> =
            sqlx::query_as("SELECT email FROM users WHERE id = ?")
                .bind(s.user_id)
                .fetch_optional(&state.db)
                .await?;
        let email = email
            .map(|r| r.0)
            .ok_or_else(|| ApiError::unauthorized("user no longer exists"))?;
        Ok(CurrentUser {
            user_id: s.user_id,
            email,
            token,
        })
    }
}

pub async fn open_session(db: &sqlx::SqlitePool, user_id: i64) -> ApiResult<String> {
    let token = new_token();
    sqlx::query(
        "INSERT INTO sessions (user_id, token, created_at, expires_at) VALUES (?, ?, ?, ?)",
    )
    .bind(user_id)
    .bind(&token)
    .bind(now())
    .bind(now() + SESSION_TTL_SECS)
    .execute(db)
    .await?;
    Ok(token)
}

#[derive(Deserialize)]
pub struct RegisterReq {
    email: String,
    password: String,
    name: Option<String>,
}

async fn register(
    State(state): State<AppState>,
    Json(body): Json<RegisterReq>,
) -> ApiResult<Json<serde_json::Value>> {
    let email = body.email.trim().to_lowercase();
    if !email.contains('@') || !email.contains('.') {
        return Err(ApiError::bad("a valid email is required"));
    }
    if body.password.len() < 8 {
        return Err(ApiError::bad("password must be at least 8 characters"));
    }
    let hash = hash_password(&body.password)?;
    let ts = now();
    let id: (i64,) = sqlx::query_as(
        "INSERT INTO users (email, password_hash, name, created_at, updated_at) VALUES (?, ?, ?, ?, ?) RETURNING id",
    )
    .bind(&email)
    .bind(&hash)
    .bind(&body.name)
    .bind(ts)
    .bind(ts)
    .fetch_one(&state.db)
    .await?;
    sqlx::query("INSERT INTO social_status (user_id, updated_at) VALUES (?, ?)")
        .bind(id.0)
        .bind(ts)
        .execute(&state.db)
        .await?;
    let token = open_session(&state.db, id.0).await?;
    let user = load_user(&state.db, id.0).await?;
    Ok(Json(json!({ "token": token, "user": user.public() })))
}

#[derive(Deserialize)]
pub struct LoginReq {
    email: String,
    password: String,
}

async fn login(
    State(state): State<AppState>,
    Json(body): Json<LoginReq>,
) -> ApiResult<Json<serde_json::Value>> {
    let email = body.email.trim().to_lowercase();
    let user: Option<UserRow> = sqlx::query_as("SELECT * FROM users WHERE email = ?")
        .bind(&email)
        .fetch_optional(&state.db)
        .await?;
    let user = user.filter(|u| verify_password(&body.password, &u.password_hash));
    let user = user.ok_or_else(|| ApiError::unauthorized("invalid email or password"))?;
    let token = open_session(&state.db, user.id).await?;
    Ok(Json(json!({ "token": token, "user": user.public() })))
}

async fn logout(State(state): State<AppState>, user: CurrentUser) -> ApiResult<Json<serde_json::Value>> {
    sqlx::query("UPDATE sessions SET revoked = 1 WHERE token = ?")
        .bind(&user.token)
        .execute(&state.db)
        .await?;
    Ok(Json(json!({ "ok": true })))
}

async fn me(user: CurrentUser) -> ApiResult<Json<serde_json::Value>> {
    Ok(Json(json!({
        "id": user.user_id,
        "email": user.email,
    })))
}

#[derive(Deserialize)]
pub struct UpdateMeReq {
    name: Option<String>,
    age: Option<i64>,
    gender: Option<String>,
    dating_intents: Option<Vec<String>>,
    relationship_goals: Option<Vec<String>>,
    city: Option<String>,
    about: Option<String>,
    discovery_enabled: Option<bool>,
    age_verified: Option<bool>,
}

async fn update_me(
    State(state): State<AppState>,
    user: CurrentUser,
    Json(body): Json<UpdateMeReq>,
) -> ApiResult<Json<serde_json::Value>> {
    let current = load_user(&state.db, user.user_id).await?;
    if let Some(age) = body.age {
        if !(18..=120).contains(&age) {
            return Err(ApiError::bad("age must be between 18 and 120"));
        }
    }
    let name = body.name.or(current.name);
    let age = body.age.or(current.age);
    let gender = body.gender.or(current.gender);
    let dating_intents = match &body.dating_intents {
        Some(items) => Some(serde_json::to_string(items).map_err(|e| ApiError::internal(format!("serialize intents: {e}")))?),
        None => current.dating_intents,
    };
    let relationship_goals = match &body.relationship_goals {
        Some(items) => Some(serde_json::to_string(items).map_err(|e| ApiError::internal(format!("serialize goals: {e}")))?),
        None => current.relationship_goals,
    };
    let city = body.city.or(current.city);
    let about = body.about.or(current.about);
    let discovery_enabled = body
        .discovery_enabled
        .map(|b| if b { 1 } else { 0 })
        .unwrap_or(current.discovery_enabled);
    let age_verified = body
        .age_verified
        .map(|b| if b { 1 } else { 0 })
        .unwrap_or(current.age_verified);
    sqlx::query(
        "UPDATE users SET name = ?, age = ?, gender = ?, dating_intents = ?, relationship_goals = ?, city = ?, about = ?, discovery_enabled = ?, age_verified = ?, updated_at = ? WHERE id = ?",
    )
    .bind(name)
    .bind(age)
    .bind(gender)
    .bind(dating_intents)
    .bind(relationship_goals)
    .bind(city)
    .bind(about)
    .bind(discovery_enabled)
    .bind(age_verified)
    .bind(now())
    .bind(user.user_id)
    .execute(&state.db)
    .await?;
    let updated = load_user(&state.db, user.user_id).await?;
    Ok(Json(json!({ "user": updated.public() })))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/register", post(register))
        .route("/login", post(login))
        .route("/logout", post(logout))
        .route("/me", get(me).patch(update_me))
}