pub mod auth;
pub mod compat;
pub mod dates;
pub mod db;
pub mod discovery;
pub mod error;
pub mod messaging;
pub mod profile;
pub mod safety;
pub mod state;
pub mod together;

use axum::extract::{Path, State};
use axum::routing::get;
use axum::{Json, Router};
use error::ApiResult;
use serde_json::{json, Value};
use state::AppState;

#[cfg(any(test, debug_assertions))]
pub mod seed;

async fn health() -> Json<Value> {
    Json(json!({
        "ok": true,
        "service": "parallel",
        "time": auth::now(),
    }))
}

async fn public_profile(state: State<AppState>, id: Path<i64>) -> ApiResult<Json<Value>> {
    profile::public_profile(state, id).await
}

pub fn app(state: AppState) -> Router {
    let r = Router::new()
        .route("/health", get(health))
        .route("/users/{id}/profile", get(public_profile))
        .nest("/auth", auth::router())
        .nest("/profile", profile::router())
        .nest("/compat", compat::router())
        .nest("/discover", discovery::router())
        .nest("/messaging", messaging::router())
        .nest("/dates", dates::router())
        .nest("/together", together::router())
        .nest("/safety", safety::router());
    #[cfg(any(test, debug_assertions))]
    let r = r.route("/dev/seed", axum::routing::post(seed::seed));
    r.with_state(state)
}

#[cfg(test)]
mod unit;