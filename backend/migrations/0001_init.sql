CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    name TEXT,
    age INTEGER,
    gender TEXT,
    dating_intents TEXT,
    relationship_goals TEXT,
    city TEXT,
    about TEXT,
    age_verified INTEGER NOT NULL DEFAULT 0,
    identity_verified INTEGER NOT NULL DEFAULT 0,
    discovery_enabled INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    created_at INTEGER NOT NULL,
    expires_at INTEGER NOT NULL,
    revoked INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(token);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);

CREATE TABLE IF NOT EXISTS profile_photos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    position INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS compatibility_features (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    feature_key TEXT NOT NULL,
    value TEXT NOT NULL,
    importance INTEGER NOT NULL DEFAULT 3,
    classification TEXT NOT NULL DEFAULT 'preference',
    visibility TEXT NOT NULL DEFAULT 'public',
    updated_at INTEGER NOT NULL,
    UNIQUE (user_id, feature_key)
);

CREATE TABLE IF NOT EXISTS interests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    path TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS introductions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    for_user INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    from_user INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason TEXT NOT NULL DEFAULT '[]',
    day INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'new',
    created_at INTEGER NOT NULL,
    UNIQUE (for_user, from_user)
);

CREATE TABLE IF NOT EXISTS introduction_requests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_user INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    to_user INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at INTEGER NOT NULL,
    UNIQUE (from_user, to_user)
);

CREATE TABLE IF NOT EXISTS connections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_a INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_b INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at INTEGER NOT NULL,
    UNIQUE (user_a, user_b)
);

CREATE TABLE IF NOT EXISTS conversations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_a INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_b INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at INTEGER NOT NULL,
    UNIQUE (user_a, user_b)
);

CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    conversation_id INTEGER NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    body TEXT NOT NULL,
    kind TEXT NOT NULL DEFAULT 'text',
    no_response_needed INTEGER NOT NULL DEFAULT 0,
    state TEXT NOT NULL DEFAULT 'sent',
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS conversation_contracts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    conversation_id INTEGER NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    rule_key TEXT NOT NULL,
    value INTEGER NOT NULL DEFAULT 0,
    UNIQUE (conversation_id, rule_key)
);

CREATE TABLE IF NOT EXISTS intent_signals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    other_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    signal TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    UNIQUE (user_id, other_id)
);

CREATE TABLE IF NOT EXISTS social_status (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    battery INTEGER NOT NULL DEFAULT 3,
    temperature TEXT NOT NULL DEFAULT 'normal',
    updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS date_preferences (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    distance_miles INTEGER NOT NULL DEFAULT 30,
    age_min INTEGER NOT NULL DEFAULT 21,
    age_max INTEGER NOT NULL DEFAULT 45,
    city TEXT,
    quiet_venues INTEGER NOT NULL DEFAULT 1,
    outside INTEGER NOT NULL DEFAULT 1,
    group_size_max INTEGER NOT NULL DEFAULT 4,
    weekdays TEXT NOT NULL DEFAULT '[]',
    weekends INTEGER NOT NULL DEFAULT 1,
    evening_ok INTEGER NOT NULL DEFAULT 1,
    daytime_ok INTEGER NOT NULL DEFAULT 1,
    updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS date_plans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    initiator_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    partner_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    plan_a TEXT NOT NULL,
    plan_b TEXT,
    plan_c TEXT,
    day INTEGER NOT NULL,
    start_at INTEGER NOT NULL,
    detail TEXT,
    state TEXT NOT NULL DEFAULT 'proposed',
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS together_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_a INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_b INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pairing_code TEXT NOT NULL UNIQUE,
    permission_scope TEXT NOT NULL DEFAULT '{"signals":true,"date_plan":true,"comfort":true}',
    created_at INTEGER NOT NULL,
    expires_at INTEGER NOT NULL,
    state TEXT NOT NULL DEFAULT 'pending'
);

CREATE TABLE IF NOT EXISTS together_signals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id INTEGER NOT NULL REFERENCES together_sessions(id) ON DELETE CASCADE,
    sender_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    signal_key TEXT NOT NULL,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS blocks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    blocker_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at INTEGER NOT NULL,
    UNIQUE (blocker_id, blocked_id)
);

CREATE TABLE IF NOT EXISTS reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    reporter_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reported_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    detail TEXT,
    status TEXT NOT NULL DEFAULT 'open',
    created_at INTEGER NOT NULL
);