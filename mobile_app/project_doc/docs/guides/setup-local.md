# Local Setup (Flutter + HeadsUp API)

This guide runs the Flutter mobile app against the local Phoenix backend.

## 1. Start the backend API

From repository root:

```bash
mix deps.get
mix ecto.setup
mix phx.server
```

Backend URL:

- `http://localhost:4000`

## 2. Prepare Flutter app

App path:

- `mobile_app/flutter_app`

If platform folders are not generated yet:

```bash
cd mobile_app/flutter_app
flutter create .
```

Install dependencies:

```bash
flutter pub get
```

## 3. Run on emulator/device

### Android emulator

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000
```

### iOS simulator

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:4000
```

### Physical device

Use your machine LAN IP:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:4000
```

## 4. Auth flow used by mobile app

The app uses JSON auth endpoints:

- `POST /api/auth/login`
- `GET /api/auth/me`
- `DELETE /api/auth/logout`

Session cookies are stored by Dio + CookieJar and sent automatically on next API calls.

## 5. Quick smoke test

1. Open app `Account` tab and login with a seeded/test user.
2. Open `Goals` tab and confirm public goals load.
3. Create a goal from `Account` tab and verify it appears in `My Goals`.
