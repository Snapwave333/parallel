use axum::body::Body;
use axum::http::{header, Request, StatusCode};
use http_body_util::BodyExt;
use parallel_backend::{app, auth, db, state};
use serde_json::{json, Value};
use state::AppState;
use tower::ServiceExt;

async fn req(
    router: &axum::Router,
    method: &str,
    path: &str,
    token: Option<&str>,
    body: Option<Value>,
) -> (StatusCode, Value) {
    let builder = Request::builder()
        .method(method)
        .uri(path.to_string())
        .header(header::CONTENT_TYPE, "application/json");
    let builder = if let Some(t) = token {
        builder.header(header::AUTHORIZATION, format!("Bearer {t}"))
    } else {
        builder
    };
    let raw = body.map(|v| Body::from(v.to_string())).unwrap_or_else(Body::empty);
    let resp = router
        .clone()
        .oneshot(builder.body(raw).unwrap())
        .await
        .unwrap();
    let status = resp.status();
    let bytes = resp.into_body().collect().await.unwrap().to_bytes();
    let json = if bytes.is_empty() {
        Value::Null
    } else {
        serde_json::from_slice(&bytes).unwrap_or(Value::Null)
    };
    (status, json)
}

async fn ok(r: &axum::Router, method: &str, path: &str, token: &str, body: Option<Value>) -> Value {
    let (status, json) = req(r, method, path, Some(token), body).await;
    assert_eq!(status, StatusCode::OK, "{} {} -> {}", method, path, json);
    json
}

async fn jget(r: &axum::Router, path: &str, token: &str) -> Value {
    ok(r, "GET", path, token, None).await
}
async fn jpost(r: &axum::Router, path: &str, token: &str, body: Value) -> Value {
    ok(r, "POST", path, token, Some(body)).await
}
async fn jput(r: &axum::Router, path: &str, token: &str, body: Value) -> Value {
    ok(r, "PUT", path, token, Some(body)).await
}
async fn jpatch(r: &axum::Router, path: &str, token: &str, body: Value) -> Value {
    ok(r, "PATCH", path, token, Some(body)).await
}
async fn jdelete(r: &axum::Router, path: &str, token: &str) -> Value {
    ok(r, "DELETE", path, token, None).await
}

async fn register(r: &axum::Router, email: &str, name: &str) -> (i64, String) {
    let (status, json) = req(
        r,
        "POST",
        "/auth/register",
        None,
        Some(json!({
            "email": email,
            "password": "password123",
            "name": name,
        })),
    )
    .await;
    assert_eq!(status, StatusCode::OK, "register {} -> {}", email, json);
    let id = json["user"]["id"].as_i64().unwrap();
    let token = json["token"].as_str().unwrap().to_string();
    (id, token)
}

fn id_of(v: &Value) -> i64 {
    v.as_i64().expect("expected i64 id")
}

#[tokio::test]
async fn end_to_end_vertical_slice() {
    let pool = db::connect("sqlite::memory:").await.unwrap();
    let router = app(AppState {
        db: pool.clone(),
        hub: state::Hub::default(),
    });

    let (alex, alex_t) = register(&router, "alex@denver.test", "Alex").await;
    let (maya, maya_t) = register(&router, "maya@denver.test", "Maya").await;
    let (cedric, cedric_t) = register(&router, "cedric@boulder.test", "Cedric").await;

    jpatch(&router, "/auth/me", &alex_t, json!({
        "age": 29, "city": "Denver", "discovery_enabled": true,
        "dating_intents": ["long_term"], "about": "Bookshop walks, quiet evenings."
    }))
    .await;
    jpatch(&router, "/auth/me", &maya_t, json!({
        "age": 27, "city": "Denver", "discovery_enabled": true,
        "dating_intents": ["long_term"], "about": "Museum days and loud libraries."
    }))
    .await;
    jpatch(&router, "/auth/me", &cedric_t, json!({
        "age": 32, "city": "Boulder", "discovery_enabled": true,
        "about": "Trail runs and burritos."
    }))
    .await;

    let aligned_features = json!([
        {"key": "communication.directness", "value": "very_direct", "importance": 5},
        {"key": "communication.response_frequency", "value": "responsive", "importance": 3},
        {"key": "planning.spontaneity", "value": "prefer_planned", "importance": 2},
        {"key": "sensory.noise_sensitivity", "value": "medium", "importance": 1}
    ]);
    jpost(&router, "/compat/features", &alex_t, json!({ "features": aligned_features })).await;
    jpost(&router, "/compat/features", &maya_t, json!({ "features": aligned_features })).await;
    jpost(&router, "/compat/interests", &alex_t, json!({ "interests": ["hiking", "coffee"] })).await;
    jpost(&router, "/compat/interests", &maya_t, json!({ "interests": ["hiking", "chess"] })).await;

    let today = jget(&router, "/discover/today", &alex_t).await;
    assert_eq!(today["count"], json!(1), "cedric must be filtered by city: {today}");
    assert_eq!(today["introductions"][0]["user_id"].as_i64().unwrap(), maya);
    assert_eq!(today["introductions"][0]["reason"]["shared_interests"], json!(1));

    let maya_today = jget(&router, "/discover/today", &maya_t).await;
    assert_eq!(maya_today["introductions"][0]["user_id"].as_i64().unwrap(), alex);

    let one_way = jpost(
        &router,
        "/discover/introduce",
        &alex_t,
        json!({ "to_user": maya, "reason": "Our profiles are a great match." }),
    )
    .await;
    assert_eq!(one_way["matched"], json!(false));

    let pending = jget(&router, "/discover/requests/incoming", &maya_t).await;
    assert_eq!(pending[0]["from_user"].as_i64().unwrap(), alex);

    let mutual = jpost(&router, "/discover/introduce", &maya_t, json!({ "to_user": alex })).await;
    assert_eq!(mutual["matched"], json!(true));
    let conv_id = id_of(&mutual["conversation_id"]);

    let conns_alex = jget(&router, "/discover/connections", &alex_t).await;
    assert_eq!(conns_alex.as_array().unwrap().len(), 1);
    let conns_maya = jget(&router, "/discover/connections", &maya_t).await;
    assert_eq!(conns_maya.as_array().unwrap().len(), 1);

    jpost(
        &router,
        &format!("/messaging/conversations/{conv_id}/messages"),
        &alex_t,
        json!({ "body": "Hey Maya! Coffee this weekend?" }),
    )
    .await;
    let msgs = jget(&router, &format!("/messaging/conversations/{conv_id}/messages"), &maya_t).await;
    assert_eq!(msgs["messages"].as_array().unwrap().len(), 1);
    assert_eq!(msgs["messages"][0]["body"], json!("Hey Maya! Coffee this weekend?"));

    let catalog = jget(&router, "/messaging/contracts/catalog", &alex_t).await;
    assert_eq!(catalog.as_array().unwrap().len(), 7);
    jput(
        &router,
        &format!("/messaging/conversations/{conv_id}/contract"),
        &alex_t,
        json!({ "rules": [
            {"key": "double_texting", "enabled": true},
            {"key": "talk_first", "enabled": true}
        ]}),
    )
    .await;
    let contract = jget(
        &router,
        &format!("/messaging/conversations/{conv_id}/contract"),
        &maya_t,
    )
    .await;
    let rules = contract["rules"].as_array().unwrap();
    assert!(rules.iter().any(|r| r["key"] == "double_texting" && r["enabled"] == true));
    assert!(rules.iter().any(|r| r["key"] == "talk_first" && r["enabled"] == true));

    jpost(
        &router,
        &format!("/messaging/intent/{maya}"),
        &alex_t,
        json!({ "signal": "romantic" }),
    )
    .await;
    let intent_a = jget(&router, &format!("/messaging/intent/{maya}"), &alex_t).await;
    assert_eq!(intent_a["theirs_revealed"], json!(false));
    jpost(
        &router,
        &format!("/messaging/intent/{alex}"),
        &maya_t,
        json!({ "signal": "romantic" }),
    )
    .await;
    let intent_b = jget(&router, &format!("/messaging/intent/{maya}"), &alex_t).await;
    assert_eq!(intent_b["mutual"], json!("romantic"));

    jput(&router, "/messaging/status/me", &maya_t, json!({ "battery": 2, "temperature": "quiet" })).await;
    let status = jget(&router, &format!("/messaging/status/{maya}"), &alex_t).await;
    assert_eq!(status["battery"], json!(2));
    assert_eq!(status["temperature"], json!("quiet"));

    jput(&router, "/dates/prefs", &alex_t, json!({ "distance_miles": 25, "city": "Denver" })).await;
    let prefs = jget(&router, "/dates/prefs", &alex_t).await;
    assert_eq!(prefs["distance_miles"], json!(25));

    let plan = jpost(&router, "/dates/plans", &alex_t, json!({
        "partner_id": maya,
        "title": "Museum + quiet cafe",
        "plan_a": "Denver Art Museum, then cafe",
        "plan_b": "Bookshop crawl",
        "day": (auth::now() / 86400) + 1,
        "detail": "No loud crowds. ~2 hours."
    }))
    .await;
    let plan_id = id_of(&plan["id"]);
    jpost(&router, &format!("/dates/plans/{plan_id}/accept"), &maya_t, json!({})).await;
    let done = jpost(&router, &format!("/dates/plans/{plan_id}/done"), &alex_t, json!({})).await;
    assert_eq!(done["state"], json!("completed"));

    let session = jpost(&router, "/together/sessions", &alex_t, json!({ "partner_id": maya })).await;
    let code = session["pairing_code"].as_str().unwrap().to_string();
    let sid = id_of(&session["id"]);
    let joined = jpost(&router, "/together/join", &maya_t, json!({ "pairing_code": code })).await;
    assert_eq!(joined["state"], json!("active"));
    jpost(&router, &format!("/together/sessions/{sid}/signal"), &maya_t, json!({ "signal": "quiet" })).await;
    let active = jget(&router, "/together/sessions", &alex_t).await;
    assert!(active["sessions"].as_array().unwrap().iter().any(|s| s["id"] == sid && s["state"] == "active"));
let ended = jpost(&router, &format!("/together/sessions/{sid}/end"), &alex_t, json!({})).await;
assert_eq!(ended["ok"], json!(true));

    jpost(&router, "/safety/blocks", &alex_t, json!({ "user_id": cedric })).await;
    let blocks = jget(&router, "/safety/blocks", &alex_t).await;
    assert!(blocks.as_array().unwrap().iter().any(|b| b["blocked_id"] == cedric));
    jdelete(&router, &format!("/safety/blocks/{cedric}"), &alex_t).await;
    jpost(
        &router,
        "/safety/reports",
        &alex_t,
        json!({ "user_id": cedric, "category": "harassment", "reason": "Not a match." }),
    )
    .await;
    let reports = jget(&router, "/safety/reports", &alex_t).await;
    assert_eq!(reports[0]["reported_id"].as_i64().unwrap(), cedric);

    let (status, seeded) = req(&router, "POST", "/dev/seed", None, None).await;
    assert_eq!(status, StatusCode::OK);
    let users = seeded["seeded"].as_array().unwrap();
    assert_eq!(users.len(), 3);
    for u in users {
        assert!(u["token"].as_str().unwrap().len() > 10);
        let (s, who) = req(
            &router,
            "GET",
            "/auth/me",
            Some(u["token"].as_str().unwrap()),
            None,
        )
        .await;
        assert_eq!(s, StatusCode::OK, "seeded token must work: {who}");
    }

    let (s, pubp) = req(&router, "GET", &format!("/users/{maya}/profile"), None, None).await;
    assert_eq!(s, StatusCode::OK);
    assert_eq!(pubp["user"]["name"], json!("Maya"));
    assert!(pubp["features"].as_array().unwrap().len() >= 1);
}