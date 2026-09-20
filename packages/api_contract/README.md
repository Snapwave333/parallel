# Parallel API Contract

Rust backend: Axum + SQLite. All request/response bodies are JSON
(`Content-Type: application/json`). Private endpoints require a bearer token:

```
Authorization: Bearer <token>
```

Errors are JSON with a single key: `{"error": "<message>"}`, with an appropriate
HTTP status code.

This contract is produced from the live implementation and is exercised end to
end by `backend/tests/e2e.rs` and the live smoke run.

---

## Health & public

| Method | Path                 | Auth | Body / Notes                       |
| ------ | -------------------- | ---- | ---------------------------------- |
| GET    | `/health`            | no   | `{"ok":true,"service":"parallel","time":<unix>}` |
| GET    | `/users/{id}/profile`| no   | Public profile (see below).        |
| POST   | `/dev/seed`          | no   | **Debug builds only.** Seeds 3 demo users (Alex, Maya, Cedric) and returns fresh tokens. |

Public profile response:

```json
{
  "user": {
    "id": 2, "name": "Maya", "age": 27, "gender": null,
    "city": "Denver", "about": null, "dating_intents": [], "relationship_goals": [],
    "age_verified": false, "identity_verified": false
  },
  "features": []
}
```

Seeded users (`/dev/seed`):

```json
{"seeded":[{"user_id":1,"email":"seed.alex@example.com","name":"Alex","password":"password123","token":"<token>"}]}
```

---

## Auth — `/auth`

| Method | Path       | Auth | Body / Notes |
| ------ | ---------- | ---- | -------- |
| POST   | `/register`| no   | `{"email","password","name"?}` → `{"token","user":{...public...}}` (401 on duplicate email) |
| POST   | `/login`   | no   | `{"email","password"}` → `{"token","user":{...public...}}` |
| POST   | `/logout`  | yes  | `{}` → `{"ok":true}` |
| GET    | `/me`      | yes  | `{"id","email"}` |
| PATCH  | `/me`      | yes  | `{"name"?,"age"?,"gender"?,"dating_intents"?,"relationship_goals"?,"city"?,"about"?,"discovery_enabled"?}` → `{"user":{...public...}}` |

**Note:** `discovery_enabled` gates appearing in other users' `/discover/today`
lists and is the switch the app's "turn discovery off" toggle flips.

---

## Profiles & photos — `/profile`

| Method | Path           | Auth | Body / Notes |
| ------ | -------------- | ---- | ------------ |
| GET    | `/profile/me`  | yes  | The caller's full private profile + photos |
| POST   | `/profile/photos` | yes | `{"url","position"?}` → `{"id","url","position"}` |
| DELETE | `/profile/photos/{id}` | yes | → `{"ok":true}` |

---

## Compatibility — `/compat`

| Method | Path              | Auth | Body / Notes |
| ------ | ----------------- | ---- | ------------ |
| GET    | `/compat/catalog` | yes  | Dimensions & features reference (labels, ordinal flag, valid options) |
| GET    | `/compat/features`| yes  | The caller's stored features |
| POST   | `/compat/features`| yes  | `{"features":[{"key","value","importance","classification"?,"visibility"?}]}` — upsert |
| DELETE | `/compat/features/{key}` | yes | → `{"ok":true}` |
| GET    | `/compat/interests` | yes | `{"interests":[...]}` |
| POST   | `/compat/interests` | yes | `{"interests":[...]}` — replace |
| GET    | `/compat/explain/{other_id}` | yes | Full comparison report vs another user |

Example `POST /compat/features`:

```json
{"features":[
  {"key":"communication.directness","value":"very_direct","importance":5},
  {"key":"sensory.noise_sensitivity","value":"medium","importance":1}
]}
```

### Catalog shape

`GET /compat/catalog` returns a flat array grouped by dimension:

```json
[{"dimension":"Communication","features":[
  {"key":"communication.directness","label":"Directness","ordinal":true,"options":["Prefers to hint","Mixed","Direct","Very direct"]}
]}]
```

### Feature catalogue (`GET /compat/catalog` — key, dimension, ordinal, options)

| Key | Dimension | Ordinal | Options |
| --- | --------- | ------- | ------- |
| `communication.directness` | Communication | yes | prefers_indirect, mixed, direct, very_direct |
| `communication.message_length` | Communication | yes | short, medium, long, any |
| `communication.response_frequency` | Communication | yes | rare, occasional, responsive, immediate |
| `communication.call_comfort` | Communication | yes | no, with_notice, yes |
| `communication.silence_comfort` | Communication | yes | low, ok, high |
| `communication.text_difficult_convos` | Communication | yes | no, sometimes, yes |
| `social_energy.crowd_tolerance` | Social Energy | yes | low, medium, high |
| `social_energy.group_size` | Social Energy | yes | very_small, small, medium, large |
| `social_energy.alone_time` | Social Energy | yes | low, medium, high |
| `social_energy.recovery_time` | Social Energy | yes | none, short, long |
| `social_energy.parallel_play` | Social Energy | yes | no, sometimes, yes |
| `sensory.noise_sensitivity` | Sensory | yes | low, medium, high |
| `sensory.light_sensitivity` | Sensory | yes | low, medium, high |
| `sensory.crowd_sensitivity` | Sensory | yes | low, medium, high |
| `sensory.touch_sensitivity` | Sensory | yes | low, medium, high |
| `affection.public_affection` | Affection | yes | never, sometimes, yes |
| `affection.ask_before_touch` | Affection | yes | never, sometimes, always |
| `planning.advance_notice` | Planning | yes | same_day, days, week |
| `planning.spontaneity` | Planning | yes | prefer_planned, flexible, love_spontaneous |
| `planning.reminders` | Planning | yes | none, gentle, firm |
| `routine.sleep_schedule` | Routine | yes | early, normal, night |
| `routine.work_schedule` | Routine | yes | daytime, flexible, night, shifts |
| `lifestyle.alcohol` | Lifestyle | yes | none, rare, social, frequent |
| `lifestyle.smoking` | Lifestyle | yes | no, rarely, yes |
| `lifestyle.pets` | Lifestyle | yes | no, ok, love |
| `lifestyle.children` | Lifestyle | yes | no, open, have_or_want |
| `relationship.goals` | Relationship | yes | casual, see_how_it_goes, long_term |
| `relationship.monogamy` | Relationship | no | monogamous, open_with_context, unsure |
| `conflict.first_reaction` | Conflict | yes | talk_immediately, cool_down_first, text_first, structured, unsure |
| `conflict.useful_conflict` | Conflict | no | space, direct, reassurance, mixed |
| `exec.function_planning` | Executive Function | yes | difficult, mixed, strong |
| `exec.function_forgotten` | Executive Function | yes | sensitive, fine |
| `exec.function_last_minute` | Executive Function | yes | very_bad, ok, fine |

### Comparison report (`GET /compat/explain/{other_id}`)

```json
{
  "dealbreaker_conflicts": [],
  "dimensions": [
    {"dimension":"Communication","label":"Directness","alignment":"Aligned","compat":1.0,"importance":{"a":5,"b":5},"items":{
       "a":{"value":"very_direct"},"b":{"value":"very_direct"}
    }}
  ],
  "shared_interests": 1,
  "explain": [{"level":"easy","text":"Direct communication (Both: very direct)"}]
}
```

- Ordinal compatibility per feature: `1 - |ia - ib| / (n - 1)`.
- Dimension alignment: `>= 0.72` → `Aligned`, `>= 0.45` → `Complementary`,
  else `PotentialFriction`; labelled `Unknown` when either side has no data
  for the dimension's features.
- Explain levels: `easy` (>= 0.72), `talk` (mismatch worth discussing),
  `unknown` (data missing).
- Dealbreaker conflict: a feature classified `dealbreaker` by one partner where
  the two sit at **extreme opposite** ends of the ordinal scale.

---

## Discovery — `/discover`

| Method | Path      | Auth | Body / Notes |
| ------ | --------- | ---- | ------------ |
| GET    | `/today`  | yes  | Today's introductions, capped at 5, filtered by city + discovery_enabled, excluding anyone already introduced (any status). |
| POST   | `/introduce` | yes | `{"to_user","reason"?}` → `{"matched":false,"message":"Introduction sent."}` or `{"matched":true,"conversation_id":<id>,"message":"You both wanted an introduction."}` |
| GET    | `/requests/incoming` | yes | Pending introduction requests |
| GET    | `/requests/outgoing` | yes | Introductions you sent that are pending |
| POST   | `/requests/{id}/accept` | yes | Accept → creates the connection + conversation, returns `{"ok":true,"conversation_id":<id>}` |
| POST   | `/requests/{id}/decline` | yes | `{"ok":true}` |
| GET    | `/connections` | yes | Your accepted connections |

`GET /discover/today`:

```json
{
  "count": 1,
  "day": 20752,
  "introductions": [
    {"user_id": 2, "reason": {
      "overall": 83.0,
      "shared_interests": 1,
      "explain": [
        {"level":"easy","text":"Direct communication (Both: very direct)"},
        {"level":"talk","text":"Noise sensitivity (medium vs high)"}
      ]
    }}
  ]
}
```

Duplicate introduces are rejected with `409`.

---

## Messaging — `/messaging`

| Method | Path | Auth | Body / Notes |
| ------ | ---- | ---- | ------------ |
| GET    | `/conversations` | yes | `{"conversations":[...]}` |
| POST   | `/conversations` | yes | `{"other_user_id"}` → `{"id","ok":true}` (idempotent: reuses existing) |
| GET    | `/conversations/{id}/messages` | yes | `{"conversation_id","messages":[...]}`; query `?after_id=` for paging |
| POST   | `/conversations/{id}/messages` | yes | `{"body","kind"?,"no_response_needed"?}` → `{"type":"message","message":{...}}` |
| GET    | `/conversations/{id}/contract` | yes | `{"conversation_id","rules":[...]}` |
| PUT    | `/conversations/{id}/contract` | yes | `{"rules":[{"key","enabled"}]}` — you can only edit your own side |
| GET    | `/contracts/catalog` | yes | The 7 rule keys with labels + defaults |
| GET    | `/intent/{other_id}` | yes | `{"mine","mutual":<signal-or-null>,"theirs_revealed":bool}` |
| POST   | `/intent/{other_id}` | yes | `{"signal"}` — commits your intent toward that person |
| GET    | `/status/me` | yes | `{"battery":0-4,"temperature":"chatty|normal|quiet|low_energy|space"}` |
| PUT    | `/status/me` | yes | `{"battery"?,"temperature"?}` — social-capacity self-report |
| GET    | `/status/{other_id}` | yes | Their current status (needs a shared conversation) |
| WS     | `/ws/chat?token=...&conversation_id=...` | token | Real-time chat events |

### Social-intent signals

`romantic | more_time | friendship | unsure | meet | not_compatible`.
An intent toward B is revealed to B the same moment A commits it
(`theirs_revealed: true` from B's side). When both signal the same value,
`mutual` returns that value.

### Social-capacity status

`battery`: 0–4 drained-to-full. `temperature`:

| key | meaning |
| --- | ------- |
| `chatty` | up for a lot of conversation |
| `normal` | default |
| `quiet` | want connection but less chatter |
| `low_energy` | running on fumes, still trying |
| `space` | need room, will be slower |

### Contract rules catalogue (`GET /contracts/catalog`)

7 keys: `double_texting`, `long_messages`, `memes`, `direct_questions`,
`day_to_respond`, `constant_conversation`, `talk_first`.

---

## Dates — `/dates`

| Method | Path | Auth | Body / Notes |
| ------ | ---- | ---- | ------------ |
| GET    | `/prefs` | yes | Your date preferences |
| PUT    | `/prefs` | yes | `{"distance_miles"?,"age_min"?,"age_max"?,"city"?,"quiet_venues"?,"outside"?,"group_size_max"?,"weekdays"?,"weekends"?,"evening_ok"?,"daytime_ok"?}` (day only prefs-visible if a connection exists) |
| GET    | `/plans` | yes | `{"plans":[...]}` |
| POST   | `/plans` | yes | `{"partner_id","title","plan_a","plan_b"?,"plan_c"?,"day","start_at"?,"detail"?}` → `{"id","state":"pending"}` |
| POST   | `/plans/{id}/accept` | yes | `{}` → `{"id","state":"accepted"}` |
| POST   | `/plans/{id}/decline` | yes | `{}` → `{"id","state":"declined"}` |
| POST   | `/plans/{id}/done` | yes | `{}` → `{"id","state":"completed"}` (cancelled if not accepted) |

`day` is a day ordinal (`now() / 86400`); the app computes it the same way.

---

## Together (live co-presence sessions) — `/together`

| Method | Path | Auth | Body / Notes |
| ------ | ---- | ---- | ------------ |
| GET    | `/sessions` | yes | `{"sessions":[...]}` — your waiting/active sessions |
| POST   | `/sessions` | yes | `{"partner_id"}` → session with 6-digit `pairing_code`, state `waiting` |
| POST   | `/join` | yes | `{"pairing_code"}` → state `active` (only the named partner may join) |
| POST   | `/sessions/{id}/signal` | yes | `{"signal"}` — a signal key sent to the room |
| POST   | `/sessions/{id}/end` | yes | `{}` → `{"ok":true}` |
| WS     | `/ws/session?token=...&session_id=...` | token | Live session events (`joined`, `signal`) |

Signal keys: `quiet | overwhelmed | enjoying | need_exit | low_energy | laugh |
breather | present`.

---

## Safety — `/safety`

| Method | Path | Auth | Body / Notes |
| ------ | ---- | ---- | ------------ |
| GET    | `/blocks` | yes | Your blocked-user list |
| POST   | `/blocks` | yes | `{"user_id"}` → `{"ok":true}` (blocks + unmatch + removes future introductions) |
| DELETE | `/blocks/{id}` | yes | `{"ok":true}` |
| GET    | `/reports` | yes | Your reports |
| POST   | `/reports` | yes | `{"user_id","category"?,"reason"?}` → `{"ok":true,"message":"..."}` |

Report categories include `harassment | inappropriate | scam | other`.

---

## WebSockets

Both WS endpoints authenticate with the token as a query parameter (active JWT
session tokens work):

- `/ws/chat?token=<token>&conversation_id=<id>` — new message events
- `/ws/session?token=<token>&session_id=<id>` — together-session events

Events are JSON objects with a `type` field:
`{"type":"message","message":{...}}`, `{"type":"joined"}`,
`{"type":"signal","signal":"quiet","user_id":1,"created_at":...}`.