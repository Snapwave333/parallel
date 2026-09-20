use crate::auth::{now, CurrentUser};
use crate::error::{ApiError, ApiResult};
use crate::state::AppState;
use axum::extract::{Path, State};
use axum::routing::get;
use axum::{Json, Router};
use serde::Deserialize;
use serde_json::{json, Value};

#[derive(Deserialize)]
pub struct PrefsReq {
    distance_miles: Option<i64>,
    age_min: Option<i64>,
    age_max: Option<i64>,
    city: Option<String>,
    quiet_venues: Option<bool>,
    outside: Option<bool>,
    group_size_max: Option<i64>,
    weekdays: Option<Vec<String>>,
    weekends: Option<bool>,
    evening_ok: Option<bool>,
    daytime_ok: Option<bool>,
}

pub async fn prefs_get(db: &sqlx::SqlitePool, user_id: i64) -> ApiResult<Value> {
    let row: Option<(Option<i64>, Option<i64>, Option<i64>, Option<String>, i64, i64, Option<i64>, Option<String>, i64, i64, i64)> =
        sqlx::query_as("SELECT distance_miles, age_min, age_max, city, quiet_venues, outside, group_size_max, weekdays, weekends, evening_ok, daytime_ok FROM date_preferences WHERE user_id = ?")
            .bind(user_id)
            .fetch_optional(db)
            .await?;
    match row {
        Some((dist, amin, amax, city, quiet, outside, group, weekdays, weekends, evening, daytime)) => {
            Ok(json!({
                "distance_miles": dist,
                "age_min": amin,
                "age_max": amax,
                "city": city,
                "quiet_venues": quiet == 1,
                "outside": outside == 1,
                "group_size_max": group,
                "weekdays": crate::auth::parse_list(&weekdays),
                "weekends": weekends == 1,
                "evening_ok": evening == 1,
                "daytime_ok": daytime == 1,
            }))
        }
        None => Ok(json!({
            "distance_miles": 30, "age_min": 21, "age_max": 45, "city": null,
            "quiet_venues": true, "outside": true, "group_size_max": 4,
            "weekdays": [], "weekends": true, "evening_ok": true, "daytime_ok": true,
        })),
    }
}

async fn prefs_route(State(state): State<AppState>, user: CurrentUser) -> ApiResult<Json<Value>> {
    Ok(Json(prefs_get(&state.db, user.user_id).await?))
}

async fn prefs_put(
    State(state): State<AppState>,
    user: CurrentUser,
    Json(body): Json<PrefsReq>,
) -> ApiResult<Json<Value>> {
    if let Some(g) = body.group_size_max {
        if !(1..=8).contains(&g) {
            return Err(ApiError::bad("group_size_max must be 1..8"));
        }
    }
    let current = prefs_get(&state.db, user.user_id).await?;
    let weekdays = match &body.weekdays {
        Some(days) => {
            for d in days {
                if !["mon", "tue", "wed", "thu", "fri", "sat", "sun"].contains(&d.as_str()) {
                    return Err(ApiError::bad("invalid weekday"));
                }
            }
            serde_json::to_string(days).map_err(|e| ApiError::internal(format!("serialize weekdays: {e}")))?
        }
        None => match current["weekdays"].as_array() {
            Some(arr) => serde_json::to_string(arr).map_err(|e| ApiError::internal(format!("serialize weekdays: {e}")))?,
            None => "[]".to_string(),
        },
    };
    let cur_i = |k: &str, d: i64| current[k].as_i64().unwrap_or(d);
    let cur_s = |k: &str| -> Option<String> {
        current[k].as_str().map(|s| s.to_string())
    };
    let cur_b = |k: &str, d: bool| current[k].as_bool().unwrap_or(d);
    let distance = body.distance_miles.unwrap_or_else(|| cur_i("distance_miles", 30));
    let age_min = body.age_min.unwrap_or_else(|| cur_i("age_min", 21));
    let age_max = body.age_max.unwrap_or_else(|| cur_i("age_max", 45));
    let city = body.city.or_else(|| cur_s("city"));
    let quiet = body.quiet_venues.unwrap_or_else(|| cur_b("quiet_venues", true));
    let outside = body.outside.unwrap_or_else(|| cur_b("outside", true));
    let group = body.group_size_max.unwrap_or_else(|| cur_i("group_size_max", 4));
    let weekends = body.weekends.unwrap_or_else(|| cur_b("weekends", true));
    let evening = body.evening_ok.unwrap_or_else(|| cur_b("evening_ok", true));
    let daytime = body.daytime_ok.unwrap_or_else(|| cur_b("daytime_ok", true));
    sqlx::query(
        "INSERT INTO date_preferences (user_id, distance_miles, age_min, age_max, city, quiet_venues, outside, group_size_max, weekdays, weekends, evening_ok, daytime_ok, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(user_id) DO UPDATE SET distance_miles = excluded.distance_miles, age_min = excluded.age_min, age_max = excluded.age_max, city = excluded.city, quiet_venues = excluded.quiet_venues, outside = excluded.outside, group_size_max = excluded.group_size_max, weekdays = excluded.weekdays, weekends = excluded.weekends, evening_ok = excluded.evening_ok, daytime_ok = excluded.daytime_ok, updated_at = excluded.updated_at",
    )
    .bind(user.user_id)
    .bind(distance)
    .bind(age_min)
    .bind(age_max)
    .bind(city)
    .bind(if quiet { 1 } else { 0 })
    .bind(if outside { 1 } else { 0 })
    .bind(group)
    .bind(weekdays)
    .bind(if weekends { 1 } else { 0 })
    .bind(if evening { 1 } else { 0 })
    .bind(if daytime { 1 } else { 0 })
    .bind(crate::auth::now())
    .execute(&state.db)
    .await?;
    Ok(Json(prefs_get(&state.db, user.user_id).await?))
}

#[derive(Deserialize)]
pub struct PlanReq {
    partner_id: i64,
    title: String,
    plan_a: String,
    plan_b: Option<String>,
    plan_c: Option<String>,
    day: i64,
    start_at: Option<i64>,
    detail: Option<String>,
}

async fn new_plan(
    State(state): State<AppState>,
    user: CurrentUser,
    Json(body): Json<PlanReq>,
) -> ApiResult<Json<Value>> {
    if body.partner_id == user.user_id {
        return Err(ApiError::bad("cannot plan a date with yourself"));
    }
    crate::auth::load_user(&state.db, body.partner_id).await?;
    if body.title.trim().is_empty() {
        return Err(ApiError::bad("title is required"));
    }
    let ts = now();
    let (id,): (i64,) = sqlx::query_as(
        "INSERT INTO date_plans (initiator_id, partner_id, title, plan_a, plan_b, plan_c, day, start_at, detail, state, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?) RETURNING id",
    )
    .bind(user.user_id)
    .bind(body.partner_id)
    .bind(&body.title)
    .bind(&body.plan_a)
    .bind(&body.plan_b)
    .bind(&body.plan_c)
    .bind(body.day)
    .bind(body.start_at.unwrap_or_else(|| body.day * 86400))
    .bind(&body.detail)
    .bind(ts)
    .fetch_one(&state.db)
    .await?;
    Ok(Json(json!({ "id": id, "state": "pending" })))
}

fn plan_row(r: (i64, i64, i64, String, String, Option<String>, Option<String>, i64, Option<i64>, Option<String>, String)) -> Value {
    let (id, initiator, partner, title, plan_a, plan_b, plan_c, day, start_at, detail, state) = r;
    json!({
        "id": id,
        "initiator_id": initiator,
        "partner_id": partner,
        "title": title,
        "plan_a": plan_a,
        "plan_b": plan_b,
        "plan_c": plan_c,
        "day": day,
        "start_at": start_at,
        "detail": detail,
        "state": state,
    })
}

async fn list_plans(State(state): State<AppState>, user: CurrentUser) -> ApiResult<Json<Value>> {
    let rows: Vec<(i64, i64, i64, String, String, Option<String>, Option<String>, i64, Option<i64>, Option<String>, String)> =
        sqlx::query_as(
            "SELECT id, initiator_id, partner_id, title, plan_a, plan_b, plan_c, day, start_at, detail, state FROM date_plans WHERE initiator_id = ? OR partner_id = ? ORDER BY state = 'pending' DESC, day",
        )
        .bind(user.user_id)
        .bind(user.user_id)
        .fetch_all(&state.db)
        .await?;
    let mut out = Vec::new();
    for r in rows {
        let row = plan_row(r);
        let other = if row["initiator_id"].as_i64() == Some(user.user_id) {
            row["partner_id"].as_i64().unwrap_or(0)
        } else {
            row["initiator_id"].as_i64().unwrap_or(0)
        };
        let u = crate::auth::load_user(&state.db, other).await?;
        let mut v = row;
        v["other_user"] = json!(u.public());
        out.push(json!({ "plan": v }));
    }
    Ok(Json(json!({ "plans": out })))
}

async fn plan_respond(
    State(state): State<AppState>,
    user: CurrentUser,
    Path((id, action)): Path<(i64, String)>,
) -> ApiResult<Json<Value>> {
    let row: Option<(i64, String)> = sqlx::query_as(
        "SELECT partner_id, state FROM date_plans WHERE id = ?",
    )
    .bind(id)
    .fetch_optional(&state.db)
    .await?;
    let (partner_id, status) = row.ok_or_else(|| ApiError::not_found("plan not found"))?;
    if partner_id != user.user_id {
        return Err(ApiError::forbidden("not the invited partner"));
    }
    if status != "pending" {
        return Err(ApiError::conflict("plan already handled"));
    }
    match action.as_str() {
        "accept" => {
            sqlx::query("UPDATE date_plans SET state = 'accepted' WHERE id = ?")
                .bind(id)
                .execute(&state.db)
                .await?;
        }
        "decline" => {
            sqlx::query("UPDATE date_plans SET state = 'declined' WHERE id = ?")
                .bind(id)
                .execute(&state.db)
                .await?;
        }
        _ => return Err(ApiError::bad("action must be accept or decline")),
    }
    Ok(Json(json!({ "id": id, "state": action })))
}

async fn plan_done(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(id): Path<i64>,
) -> ApiResult<Json<Value>> {
    let row: Option<(i64, i64, String)> = sqlx::query_as(
        "SELECT initiator_id, partner_id, state FROM date_plans WHERE id = ?",
    )
    .bind(id)
    .fetch_optional(&state.db)
    .await?;
    let (initiator, partner, status) = row.ok_or_else(|| ApiError::not_found("plan not found"))?;
    if initiator != user.user_id && partner != user.user_id {
        return Err(ApiError::forbidden("not a participant"));
    }
    let new_state = if status == "accepted" { "completed" } else { "cancelled" };
    sqlx::query("UPDATE date_plans SET state = ? WHERE id = ?")
        .bind(new_state)
        .bind(id)
        .execute(&state.db)
        .await?;
    if new_state == "completed" {
        crate::discovery::ensure_connection(&state.db, initiator, partner).await?;
    }
    Ok(Json(json!({ "id": id, "state": new_state })))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/prefs", get(prefs_route).put(prefs_put))
        .route("/plans", get(list_plans).post(new_plan))
        .route("/plans/{id}/{action}", axum::routing::post(plan_respond))
        .route("/plans/{id}/done", axum::routing::post(plan_done))
}