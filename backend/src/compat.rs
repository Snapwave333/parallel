use crate::auth::{now, CurrentUser};
use crate::error::{ApiError, ApiResult};
use crate::state::AppState;
use axum::extract::{Path, State};
use axum::routing::{delete, get};
use axum::{Json, Router};
use serde::Deserialize;
use serde_json::{json, Value};
use sqlx::FromRow;

pub const DIRECTNESS: &[&str] = &["prefers_indirect", "mixed", "direct", "very_direct"];
pub const MSG_LEN: &[&str] = &["short", "medium", "long", "any"];
pub const RESP_FREQ: &[&str] = &["rare", "occasional", "responsive", "immediate"];
pub const CALL_COMFORT: &[&str] = &["no", "with_notice", "yes"];
pub const SILENCE: &[&str] = &["low", "ok", "high"];
pub const TEXT_HARD: &[&str] = &["no", "sometimes", "yes"];
pub const CROWD_TOL: &[&str] = &["low", "medium", "high"];
pub const GROUP_SIZE: &[&str] = &["very_small", "small", "medium", "large"];
pub const ALONE_TIME: &[&str] = &["low", "medium", "high"];
pub const RECOVERY: &[&str] = &["none", "short", "long"];
pub const PARALLEL_PLAY: &[&str] = &["no", "sometimes", "yes"];
pub const SENS: &[&str] = &["low", "medium", "high"];
pub const PUBLIC_AFFECTION: &[&str] = &["never", "sometimes", "yes"];
pub const ASK_TOUCH: &[&str] = &["never", "sometimes", "always"];
pub const ADVANCE: &[&str] = &["same_day", "days", "week"];
pub const SPONTANEITY: &[&str] = &["prefer_planned", "flexible", "love_spontaneous"];
pub const REMINDERS: &[&str] = &["none", "gentle", "firm"];
pub const SLEEP: &[&str] = &["early", "normal", "night"];
pub const WORK: &[&str] = &["daytime", "flexible", "night", "shifts"];
pub const ALCOHOL: &[&str] = &["none", "rare", "social", "frequent"];
pub const SMOKING: &[&str] = &["no", "rarely", "yes"];
pub const PETS: &[&str] = &["no", "ok", "love"];
pub const CHILDREN: &[&str] = &["no", "open", "have_or_want"];
pub const GOALS: &[&str] = &["casual", "see_how_it_goes", "long_term"];
pub const MONOGAMY: &[&str] = &["monogamous", "open_with_context", "unsure"];
pub const CONFLICT_FIRST: &[&str] = &["talk_immediately", "cool_down_first", "text_first", "structured", "unsure"];
pub const REASSURANCE: &[&str] = &["space", "direct", "reassurance", "mixed"];
pub const EXEC_PLANNING: &[&str] = &["difficult", "mixed", "strong"];
pub const FORGOTTEN: &[&str] = &["sensitive", "fine"];
pub const LAST_MINUTE: &[&str] = &["very_bad", "ok", "fine"];

#[derive(Clone, Copy)]
pub struct FeatureDef {
    pub key: &'static str,
    pub dimension: &'static str,
    pub label: &'static str,
    pub ordinal: bool,
    pub options: &'static [&'static str],
}

pub const FEATURES: &[FeatureDef] = &[
    FeatureDef { key: "communication.directness", dimension: "Communication", label: "Direct communication", ordinal: true, options: DIRECTNESS },
    FeatureDef { key: "communication.message_length", dimension: "Communication", label: "Message length", ordinal: true, options: MSG_LEN },
    FeatureDef { key: "communication.response_frequency", dimension: "Communication", label: "Response frequency", ordinal: true, options: RESP_FREQ },
    FeatureDef { key: "communication.call_comfort", dimension: "Communication", label: "Phone-call comfort", ordinal: true, options: CALL_COMFORT },
    FeatureDef { key: "communication.silence_comfort", dimension: "Communication", label: "Comfort with silence", ordinal: true, options: SILENCE },
    FeatureDef { key: "communication.text_difficult_convos", dimension: "Communication", label: "Texting during conflict", ordinal: true, options: TEXT_HARD },
    FeatureDef { key: "social_energy.crowd_tolerance", dimension: "Social Energy", label: "Crowd tolerance", ordinal: true, options: CROWD_TOL },
    FeatureDef { key: "social_energy.group_size", dimension: "Social Energy", label: "Group size", ordinal: true, options: GROUP_SIZE },
    FeatureDef { key: "social_energy.alone_time", dimension: "Social Energy", label: "Alone-time needs", ordinal: true, options: ALONE_TIME },
    FeatureDef { key: "social_energy.recovery_time", dimension: "Social Energy", label: "Recovery time after events", ordinal: true, options: RECOVERY },
    FeatureDef { key: "social_energy.parallel_play", dimension: "Social Energy", label: "Parallel play", ordinal: true, options: PARALLEL_PLAY },
    FeatureDef { key: "sensory.noise_sensitivity", dimension: "Sensory", label: "Noise sensitivity", ordinal: true, options: SENS },
    FeatureDef { key: "sensory.light_sensitivity", dimension: "Sensory", label: "Light sensitivity", ordinal: true, options: SENS },
    FeatureDef { key: "sensory.crowd_sensitivity", dimension: "Sensory", label: "Crowd sensitivity", ordinal: true, options: SENS },
    FeatureDef { key: "sensory.touch_sensitivity", dimension: "Sensory", label: "Touch sensitivity", ordinal: true, options: SENS },
    FeatureDef { key: "affection.public_affection", dimension: "Affection", label: "Public affection", ordinal: true, options: PUBLIC_AFFECTION },
    FeatureDef { key: "affection.ask_before_touch", dimension: "Affection", label: "Asking before touch", ordinal: true, options: ASK_TOUCH },
    FeatureDef { key: "planning.advance_notice", dimension: "Planning", label: "Advance notice needed", ordinal: true, options: ADVANCE },
    FeatureDef { key: "planning.spontaneity", dimension: "Planning", label: "Spontaneity tolerance", ordinal: true, options: SPONTANEITY },
    FeatureDef { key: "planning.reminders", dimension: "Planning", label: "Reminder preference", ordinal: true, options: REMINDERS },
    FeatureDef { key: "routine.sleep_schedule", dimension: "Routine", label: "Sleep schedule", ordinal: true, options: SLEEP },
    FeatureDef { key: "routine.work_schedule", dimension: "Routine", label: "Work schedule", ordinal: true, options: WORK },
    FeatureDef { key: "lifestyle.alcohol", dimension: "Lifestyle", label: "Alcohol", ordinal: true, options: ALCOHOL },
    FeatureDef { key: "lifestyle.smoking", dimension: "Lifestyle", label: "Smoking", ordinal: true, options: SMOKING },
    FeatureDef { key: "lifestyle.pets", dimension: "Lifestyle", label: "Pets", ordinal: true, options: PETS },
    FeatureDef { key: "lifestyle.children", dimension: "Lifestyle", label: "Children", ordinal: true, options: CHILDREN },
    FeatureDef { key: "relationship.goals", dimension: "Relationship", label: "Relationship goals", ordinal: true, options: GOALS },
    FeatureDef { key: "relationship.monogamy", dimension: "Relationship", label: "Relationship structure", ordinal: false, options: MONOGAMY },
    FeatureDef { key: "conflict.first_reaction", dimension: "Conflict", label: "When we disagree", ordinal: true, options: CONFLICT_FIRST },
    FeatureDef { key: "conflict.useful_conflict", dimension: "Conflict", label: "What helps when upset", ordinal: false, options: REASSURANCE },
    FeatureDef { key: "exec.function_planning", dimension: "Executive Function", label: "Planning ahead", ordinal: true, options: EXEC_PLANNING },
    FeatureDef { key: "exec.function_forgotten", dimension: "Executive Function", label: "Forgotten messages", ordinal: true, options: FORGOTTEN },
    FeatureDef { key: "exec.function_last_minute", dimension: "Executive Function", label: "Last-minute changes", ordinal: true, options: LAST_MINUTE },
];

pub fn def(key: &str) -> Option<&'static FeatureDef> {
    FEATURES.iter().find(|f| f.key == key)
}

fn display(v: &str) -> String {
    v.replace('_', " ")
}

fn option_index(def: &FeatureDef, value: &str) -> Option<usize> {
    def.options.iter().position(|o| *o == value)
}

fn aligned(compat: f32, filled_both: bool) -> &'static str {
    if !filled_both {
        return "Unknown";
    }
    if compat >= 0.72 {
        "Aligned"
    } else if compat >= 0.45 {
        "Complementary"
    } else {
        "PotentialFriction"
    }
}

pub fn feature_compat(def: &FeatureDef, a: &str, b: &str) -> f32 {
    if !def.ordinal {
        return if a == b { 1.0 } else { 0.35 };
    }
    let n = def.options.len().max(2) as f32;
    match (option_index(def, a), option_index(def, b)) {
        (Some(ia), Some(ib)) => {
            let d = (ia as f32 - ib as f32).abs() / (n - 1.0);
            1.0 - d
        }
        (Some(_), None) | (None, Some(_)) => 0.0,
        (None, None) => 1.0,
    }
}

fn values_ok(def: &FeatureDef, mine: &str, theirs: &str) -> bool {
    if !def.ordinal {
        return mine == theirs;
    }
    let n = def.options.len();
    match (option_index(def, mine), option_index(def, theirs)) {
        (Some(0), Some(t)) => t == 0,
        (Some(i), Some(t)) if i == n - 1 => t == n - 1,
        (None, _) | (_, None) => true,
        _ => true,
    }
}

fn is_dealbreaker_conflict(def: &FeatureDef, a_class: &str, b_class: &str, a_val: &str, b_val: &str) -> bool {
    if a_class == "dealbreaker" && !values_ok(def, a_val, b_val) {
        return true;
    }
    if b_class == "dealbreaker" && !values_ok(def, b_val, a_val) {
        return true;
    }
    false
}

#[derive(FromRow, Clone, serde::Serialize)]
pub struct FeatureValue {
    pub key: String,
    pub value: String,
    pub importance: i64,
    pub classification: String,
    pub visibility: String,
}

pub async fn feature_rows(db: &sqlx::SqlitePool, user_id: i64) -> ApiResult<Vec<FeatureValue>> {
    Ok(sqlx::query_as::<_, FeatureValue>(
        "SELECT feature_key AS key, value, importance, classification, visibility FROM compatibility_features WHERE user_id = ?",
    )
    .bind(user_id)
    .fetch_all(db)
    .await?)
}

#[derive(serde::Serialize)]
pub struct DimensionResult {
    pub dimension: String,
    pub label: String,
    pub alignment: String,
    pub compat: Option<f32>,
    pub importance: i64,
    pub items: Vec<String>,
}

#[derive(serde::Serialize)]
pub struct ExplainLine {
    pub level: String,
    pub text: String,
}

#[derive(serde::Serialize)]
pub struct CompareReport {
    pub dealbreaker_conflicts: Vec<String>,
    pub dimensions: Vec<DimensionResult>,
    pub shared_interests: Vec<String>,
    pub explain: Vec<ExplainLine>,
}

pub fn compare(
    mine: &[FeatureValue],
    theirs: &[FeatureValue],
    mine_interests: &[String],
    their_interests: &[String],
) -> CompareReport {
    let mine_map: std::collections::HashMap<&str, &FeatureValue> =
        mine.iter().map(|f| (f.key.as_str(), f)).collect();
    let their_map: std::collections::HashMap<&str, &FeatureValue> =
        theirs.iter().map(|f| (f.key.as_str(), f)).collect();

    let shared_interests: Vec<String> = mine_interests
        .iter()
        .filter(|m| their_interests.iter().any(|t| t.as_str() == m.as_str()))
        .cloned()
        .collect();

    let mut dealbreaker_conflicts = Vec::new();
    let mut dimensions: Vec<DimensionResult> = Vec::new();
    let mut explain: Vec<ExplainLine> = Vec::new();

    let mut by_dim: std::collections::HashMap<&'static str, Vec<(&'static FeatureDef, Option<f32>, i64, String, &'static str)>> =
        std::collections::HashMap::new();

    for f in FEATURES {
        let a = mine_map.get(f.key).copied();
        let b = their_map.get(f.key).copied();
        match (a, b) {
            (Some(a), Some(b)) => {
                if is_dealbreaker_conflict(f, &a.classification, &b.classification, &a.value, &b.value) {
                    dealbreaker_conflicts.push(format!(
                        "{} — a dealbreaker for one of you",
                        f.label
                    ));
                }
                let c = feature_compat(f, &a.value, &b.value);
                let imp = a.importance.max(b.importance);
                let item = if c >= 0.72 {
                    format!("Both: {}", display(&a.value))
                } else {
                    format!("{} vs {}", display(&a.value), display(&b.value))
                };
                explain.push(ExplainLine {
                    level: if c >= 0.72 { "easy".into() } else { "talk".into() },
                    text: format!("{} ({})", f.label, item),
                });
                by_dim
                    .entry(f.dimension)
                    .or_default()
                    .push((f, Some(c), imp, format!("{}: {}", f.label, item), aligned(c, true)));
            }
            (Some(_), None) => {
                by_dim.entry(f.dimension).or_default().push((
                    f,
                    None,
                    0,
                    format!("{} — they haven't answered", f.label),
                    "Unknown",
                ));
                explain.push(ExplainLine {
                    level: "unknown".into(),
                    text: format!("{} — no answer yet", f.label),
                });
            }
            (None, Some(_)) => {
                by_dim.entry(f.dimension).or_default().push((
                    f,
                    None,
                    0,
                    format!("{} — you haven't answered", f.label),
                    "Unknown",
                ));
                explain.push(ExplainLine {
                    level: "unknown".into(),
                    text: format!("{} — no answer yet", f.label),
                });
            }
            (None, None) => {}
        }
    }

    let mut dims: Vec<(&'static str, Vec<(&'static FeatureDef, Option<f32>, i64, String, &'static str)>)> =
        by_dim.into_iter().collect();
    dims.sort_by_key(|(d, _)| *d);

    for (dim_name, entries) in dims {
        let filled: Vec<f32> = entries.iter().filter_map(|e| e.1).collect();
        let compat = if filled.is_empty() {
            None
        } else {
            Some(filled.iter().sum::<f32>() / filled.len() as f32)
        };
        let importance = entries.iter().map(|e| e.2).max().unwrap_or(0);
        let alignment = compat
            .map(|c| aligned(c, true))
            .unwrap_or("Unknown");
        let items = entries.iter().map(|e| e.3.clone()).collect();
        dimensions.push(DimensionResult {
            dimension: dim_name.to_string(),
            label: dim_name.to_string(),
            alignment: alignment.to_string(),
            compat,
            importance,
            items,
        });
    }

    CompareReport {
        dealbreaker_conflicts,
        dimensions,
        shared_interests,
        explain,
    }
}

pub fn catalog_json() -> Value {
    let mut dims: Vec<(&'static str, Vec<Value>)> = Vec::new();
    for f in FEATURES {
        match dims.iter_mut().find(|(d, _)| *d == f.dimension) {
            Some((_, list)) => list.push(json!({
                "key": f.key, "label": f.label, "ordinal": f.ordinal,
                "options": f.options.iter().map(display_dyn).collect::<Vec<_>>(),
            })),
            None => dims.push((
                f.dimension,
                vec![json!({
                    "key": f.key, "label": f.label, "ordinal": f.ordinal,
                    "options": f.options.iter().map(display_dyn).collect::<Vec<_>>(),
                })],
            )),
        }
    }
    dims.sort_by_key(|(d, _)| *d);
    Value::Array(dims.into_iter().map(|(name, features)| json!({"dimension": name, "features": features })).collect())
}

fn display_dyn(s: &&'static str) -> String {
    display(s)
}

async fn catalog() -> Json<Value> {
    Json(catalog_json())
}

async fn my_features(
    State(state): State<AppState>,
    user: CurrentUser,
) -> ApiResult<Json<Value>> {
    let rows = feature_rows(&state.db, user.user_id).await?;
    Ok(Json(json!(rows.iter().map(|f| json!({
        "key": f.key, "value": f.value, "importance": f.importance,
        "classification": f.classification, "visibility": f.visibility,
    })).collect::<Vec<_>>())))
}

#[derive(Deserialize)]
pub struct FeatureIn {
    pub key: String,
    pub value: String,
    pub importance: i64,
    pub classification: Option<String>,
    pub visibility: Option<String>,
}

#[derive(Deserialize)]
pub struct SetFeaturesReq {
    pub features: Vec<FeatureIn>,
}

async fn set_features(
    State(state): State<AppState>,
    user: CurrentUser,
    Json(body): Json<SetFeaturesReq>,
) -> ApiResult<Json<Value>> {
    let ts = now();
    for f in &body.features {
        let d = def(&f.key).ok_or_else(|| ApiError::bad(format!("unknown feature key: {}", f.key)))?;
        if option_index(d, &f.value).is_none() && !d.options.contains(&f.value.as_str()) {
            return Err(ApiError::bad(format!(
                "invalid value '{}' for feature {}",
                f.value, f.key
            )));
        }
        if !(0..=5).contains(&f.importance) {
            return Err(ApiError::bad("importance must be 0..5"));
        }
        let classification = f.classification.as_deref().unwrap_or("preference");
        let visibility = f.visibility.as_deref().unwrap_or("public");
        if !["preference", "requirement", "dealbreaker"].contains(&classification) {
            return Err(ApiError::bad("classification must be preference, requirement or dealbreaker"));
        }
        if !["public", "mutual", "connections", "partner", "private"].contains(&visibility) {
            return Err(ApiError::bad("invalid visibility"));
        }
        sqlx::query(
            "INSERT INTO compatibility_features (user_id, feature_key, value, importance, classification, visibility, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)
             ON CONFLICT(user_id, feature_key) DO UPDATE SET value = excluded.value, importance = excluded.importance, classification = excluded.classification, visibility = excluded.visibility, updated_at = excluded.updated_at",
        )
        .bind(user.user_id)
        .bind(&f.key)
        .bind(&f.value)
        .bind(f.importance)
        .bind(classification)
        .bind(visibility)
        .bind(ts)
        .execute(&state.db)
        .await?;
    }
    my_features(State(state), user).await
}

async fn delete_feature(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(key): Path<String>,
) -> ApiResult<Json<Value>> {
    sqlx::query("DELETE FROM compatibility_features WHERE user_id = ? AND feature_key = ?")
        .bind(user.user_id)
        .bind(&key)
        .execute(&state.db)
        .await?;
    Ok(Json(json!({ "ok": true })))
}

async fn my_interests(
    State(state): State<AppState>,
    user: CurrentUser,
) -> ApiResult<Json<Value>> {
    let rows: Vec<String> = sqlx::query_as("SELECT path FROM interests WHERE user_id = ? ORDER BY id")
        .bind(user.user_id)
        .fetch_all(&state.db)
        .await?
        .into_iter()
        .map(|(p,): (String,)| p)
        .collect();
    Ok(Json(json!(rows)))
}

#[derive(Deserialize)]
pub struct SetInterestsReq {
    pub interests: Vec<String>,
}

async fn set_interests(
    State(state): State<AppState>,
    user: CurrentUser,
    Json(body): Json<SetInterestsReq>,
) -> ApiResult<Json<Value>> {
    let mut tx = state.db.begin().await?;
    sqlx::query("DELETE FROM interests WHERE user_id = ?")
        .bind(user.user_id)
        .execute(&mut *tx)
        .await?;
    for path in &body.interests {
        if path.trim().is_empty() {
            return Err(ApiError::bad("interests must not be empty"));
        }
        sqlx::query("INSERT INTO interests (user_id, path) VALUES (?, ?)")
            .bind(user.user_id)
            .bind(path.trim())
            .execute(&mut *tx)
            .await?;
    }
    tx.commit().await?;
    my_interests(State(state), user).await
}

pub async fn interests_for(db: &sqlx::SqlitePool, user_id: i64) -> ApiResult<Vec<String>> {
    Ok(sqlx::query_as("SELECT path FROM interests WHERE user_id = ? ORDER BY id")
        .bind(user_id)
        .fetch_all(db)
        .await?
        .into_iter()
        .map(|(p,): (String,)| p)
        .collect())
}

async fn explain(
    State(state): State<AppState>,
    user: CurrentUser,
    Path(other_id): Path<i64>,
) -> ApiResult<Json<Value>> {
    if other_id == user.user_id {
        return Err(ApiError::bad("cannot compare with yourself"));
    }
    let mine = feature_rows(&state.db, user.user_id).await?;
    let theirs = feature_rows(&state.db, other_id).await?;
    let mine_i = interests_for(&state.db, user.user_id).await?;
    let their_i = interests_for(&state.db, other_id).await?;
    let report = compare(&mine, &theirs, &mine_i, &their_i);
    Ok(Json(json!(report)))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/catalog", get(catalog))
        .route("/features", get(my_features).post(set_features))
        .route("/features/{key}", delete(delete_feature))
        .route("/interests", get(my_interests).post(set_interests))
        .route("/explain/{other_id}", get(explain))
}