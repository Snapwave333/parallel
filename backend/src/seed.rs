use crate::auth::{hash_password, now, open_session};
use crate::error::ApiResult;
use crate::state::AppState;
use axum::extract::State;
use axum::Json;
use serde_json::{json, Value};

struct SeedProfile {
    name: &'static str,
    age: i64,
    gender: &'static str,
    city: &'static str,
    about: &'static str,
    intents: &'static [&'static str],
    goals: &'static [&'static str],
    features: &'static [(&'static str, &'static str, i64)],
    interests: &'static [&'static str],
}

const SEED_EMAILS: &[&str] = &["seed.alex@example.com", "seed.maya@example.com", "seed.cedric@example.com"];

const ALEX: SeedProfile = SeedProfile {
    name: "Alex",
    age: 29,
    gender: "nonbinary",
    city: "Denver",
    about: "Quiet hangs, good food, long walks. Rapid-fire questions are fine if we take breaks.",
    intents: &["dating", "long_term"],
    goals: &["monogamous"],
    features: &[
        ("social_processing_stress", "often", 4),
        ("preferred_communication", "text", 5),
        ("processing_speed", "moderate", 4),
        ("overstimulation_threshold", "low", 4),
        ("needed_recovery_time", "long", 4),
        ("touch_comfort", "somewhat", 3),
        ("affection_style", "warm", 4),
        ("planned_versus_spontaneous", "mostly_planned", 4),
        ("routine_stability", "high", 4),
        ("cleanliness_standards", "high", 3),
        ("sleep_pattern", "night_owl", 3),
        ("alcohol", "never_drink", 4),
        ("diet", "vegetarian", 3),
    ],
    interests: &["hiking", "coffee", "architecture", "spreadsheets"],
};

const MAYA: SeedProfile = SeedProfile {
    name: "Maya",
    age: 27,
    gender: "woman",
    city: "Denver",
    about: "DnD nights, dogs, very direct texts. I will triple-check plans before sending them.",
    intents: &["dating", "friendship"],
    goals: &["monogamous"],
    features: &[
        ("social_processing_stress", "sometimes", 3),
        ("preferred_communication", "text", 5),
        ("processing_speed", "moderate", 3),
        ("overstimulation_threshold", "moderate", 3),
        ("needed_recovery_time", "long", 4),
        ("touch_comfort", "comfortable", 3),
        ("affection_style", "warm", 4),
        ("planned_versus_spontaneous", "always_planned", 5),
        ("routine_stability", "high", 4),
        ("cleanliness_standards", "moderate", 2),
        ("sleep_pattern", "early_bird", 3),
        ("alcohol", "sometimes", 2),
        ("diet", "no_preference", 2),
    ],
    interests: &["hiking", "board_games", "coffee", "writing"],
};

const CEDRIC: SeedProfile = SeedProfile {
    name: "Cedric",
    age: 32,
    gender: "man",
    city: "Boulder",
    about: "Live music when I have energy, otherwise a cozy couch and a book.",
    intents: &["casual", "dating"],
    goals: &["open_to_anything"],
    features: &[
        ("social_processing_stress", "rare", 2),
        ("preferred_communication", "in_person", 3),
        ("processing_speed", "fast", 3),
        ("overstimulation_threshold", "very_high", 3),
        ("needed_recovery_time", "short", 2),
        ("touch_comfort", "very_like", 4),
        ("affection_style", "open", 4),
        ("planned_versus_spontaneous", "spontaneous", 5),
        ("routine_stability", "low", 3),
        ("cleanliness_standards", "relaxed", 3),
        ("sleep_pattern", "flexible", 2),
        ("alcohol", "sometimes", 3),
        ("diet", "no_preference", 2),
    ],
    interests: &["concerts", "cycling", "books", "guitar"],
};

async fn insert_user(
    db: &sqlx::SqlitePool,
    email: &str,
    p: &SeedProfile,
) -> ApiResult<i64> {
    let hash = hash_password("password123")?;
    let ts = now();
    let (id,): (i64,) = sqlx::query_as(
        "INSERT INTO users (email, password_hash, name, age, gender, dating_intents, relationship_goals, city, about, age_verified, identity_verified, discovery_enabled, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 1, 1, ?, ?) RETURNING id",
    )
    .bind(email)
    .bind(&hash)
    .bind(p.name)
    .bind(p.age)
    .bind(p.gender)
    .bind(serde_json::to_string(p.intents)?)
    .bind(serde_json::to_string(p.goals)?)
    .bind(p.city)
    .bind(p.about)
    .bind(ts)
    .bind(ts)
    .fetch_one(db)
    .await?;
    for (key, value, importance) in p.features {
        sqlx::query(
            "INSERT OR IGNORE INTO compatibility_features (user_id, feature_key, value, importance, classification, visibility, updated_at) VALUES (?, ?, ?, ?, 'preference', 'public', ?)",
        )
        .bind(id)
        .bind(key)
        .bind(value)
        .bind(importance)
        .bind(ts)
        .execute(db)
        .await?;
    }
    for interest in p.interests {
        sqlx::query("INSERT OR IGNORE INTO interests (user_id, path) VALUES (?, ?)")
            .bind(id)
            .bind(interest)
            .execute(db)
            .await?;
    }
    sqlx::query("INSERT OR IGNORE INTO social_status (user_id, updated_at) VALUES (?, ?)")
        .bind(id)
        .bind(crate::auth::now())
        .execute(db)
        .await?;
    Ok(id)
}

pub async fn seed(State(state): State<AppState>) -> ApiResult<Json<Value>> {
    let users = &[
        (SEED_EMAILS[0], &ALEX),
        (SEED_EMAILS[1], &MAYA),
        (SEED_EMAILS[2], &CEDRIC),
    ];
    let mut ids = Vec::new();
    for (email, p) in users {
        let existing: Option<(i64,)> =
            sqlx::query_as("SELECT id FROM users WHERE email = ?")
                .bind(email)
                .fetch_optional(&state.db)
                .await?;
        let id = match existing {
            Some((id,)) => id,
            None => insert_user(&state.db, email, p).await?,
        };
        ids.push(id);
    }
    let mut tokens = Vec::new();
    for id in &ids {
        tokens.push(open_session(&state.db, *id).await?);
    }
    let mut out = Vec::new();
    for (i, id) in ids.iter().enumerate() {
        let u = crate::auth::load_user(&state.db, *id).await?;
        out.push(json!({
            "user_id": id,
            "email": users[i].0,
            "name": u.public()["name"],
            "password": "password123",
            "token": tokens[i],
        }));
    }
    Ok(Json(json!({ "seeded": out })))
}