# Mobile App Tech Stack (Flutter)

## Runtime & Language

| Layer    | Choice  | Version |
| -------- | ------- | ------- |
| Runtime  | Flutter | 3.24+   |
| Language | Dart    | 3.3+    |

## Core Packages

| Package              | Version | Purpose |
| -------------------- | ------- | ------- |
| `flutter`            | SDK     | Mobile UI framework |
| `provider`           | ^6.1.2  | App state management |
| `dio`                | ^5.7.0  | HTTP client |
| `cookie_jar`         | ^4.0.8  | Session cookie storage |
| `dio_cookie_manager` | ^3.1.1  | Dio cookie integration |

## Architecture

- Pattern: feature-light layered architecture (`core`, `models`, `services`, `state`, `screens`)
- State: `ChangeNotifier` + `provider`
- Networking: centralized `ApiClient` with typed `ApiException`
- Auth: session-cookie based via backend JSON auth endpoints

## API Integration

- Backend: existing Phoenix API in this repository
- Base URL:
  - Android emulator default: `http://10.0.2.2:4000`
  - Override via `--dart-define=API_BASE_URL=...`
- Data format: JSON envelopes (`data`, `success`, `error.message`)

## Platforms

- Primary: iOS + Android
- Web/Desktop: optional, not part of MVP scope

## Tooling

| Tool | Purpose |
| ---- | ------- |
| `flutter_lints` | Lint rules |
| `flutter test` | Unit/widget tests |
| `flutter run` | Local run/debug |

## Why this stack

- Flutter provides one codebase for iOS and Android.
- `dio` + cookie manager supports the backend's session-based auth without switching backend auth models.
- `provider` keeps the app simple and easy to evolve into Riverpod/BLoC later if needed.
