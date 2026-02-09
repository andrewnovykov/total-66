# HeadsUp Flutter App

This folder contains a Flutter client wired to the current HeadsUp Phoenix API.

## What is implemented

- Session auth via JSON API:
  - `POST /api/auth/login`
  - `GET /api/auth/me`
  - `DELETE /api/auth/logout`
- Public API usage:
  - `GET /api/goals`
  - `GET /api/goals/:id`
  - `GET /api/categories`
- Authenticated API usage:
  - `GET /api/goals/my`
  - `POST /api/goals`
  - `POST /api/goals/:id/like`
  - `DELETE /api/goals/:id/like`
  - `POST /api/goals/:id/subscribe`
  - `DELETE /api/goals/:id/subscribe`

## Project status

This is a code-first Flutter app skeleton (`lib/`, `pubspec.yaml`) and does not include generated platform folders yet.

If you have Flutter installed, run this once inside `mobile_app/flutter_app`:

```bash
flutter create .
flutter pub get
```

Then replace the generated `lib/` with the files in this folder (or run `flutter create .` first, then restore these files).

## Configure API base URL

Set API base URL in `.env`:

```text
API_BASE_URL=https://heads-up-docker.onrender.com
```

App reads this value at startup via `flutter_dotenv`.

## Run

```bash
flutter pub get
flutter run
```
