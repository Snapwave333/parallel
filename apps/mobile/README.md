# Parallel — Mobile app

Flutter client for the Parallel backend. Auth, discovery, compatibility,
messaging, dates, Together sessions and safety — all backed by the live API.

## Run it

```bash
flutter run -d windows   # or -d chrome, or an attached device
```

The app expects the backend on `http://localhost:8080` by default. Point it
elsewhere at build time:

```bash
flutter run --dart-define=API_BASE=http://192.168.1.50:8080
```

The seed users from `POST /dev/seed` are handy for a quick login.

## Layout

- `lib/core/` — API client, session state, models
- `lib/design/` — monochrome brand theme (see the master design record)
- `lib/features/` — one folder per product area (auth, discover, compat,
  messaging, dates, together, safety, you)

Model classes mirror `packages/shared_schemas/schemas.json`; the route and
payload semantics come from `packages/api_contract/README.md`.