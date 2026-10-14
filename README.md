# VitalySync Frontend

This folder contains the Flutter mobile application for VitalySync. The app provides the user interface for onboarding, authentication, wellness logging, dashboards, nutrition tracking, activity and exercise goals, reminders, settings, and the smart nudge assistant.

## Purpose Of This README

This README is only for frontend development. It should cover Flutter setup, folder structure, UI conventions, and app-specific commands.

- Full repository overview: [../README.md](../README.md)
- Academic and project write-ups: [../docs/](../docs/)
- Coding-agent rules: [../AGENTS.md](../AGENTS.md)
- Backend implementation: `../vitalysync-backend/`

## App Structure

```text
lib/
+-- main.dart                 Flutter entry point
+-- app/                      App shell, theme setup, and navigation
+-- features/                 Feature modules and screens
+-- services/                 App-level services
+-- shared/                   Reusable widgets, config, preferences, offline helpers, notifications, assistant UI
```

Feature folders currently include:

- `activity`
- `adaptive`
- `auth`
- `dashboard`
- `exercise`
- `home`
- `log`
- `notifications`
- `nutrition`
- `onboarding`
- `profile`
- `settings`

Shared folders currently include:

- `assistant`
- `config`
- `notifications`
- `offline`
- `preferences`
- `theme`
- `widgets`

## UI Direction

The frontend uses a calm wellness-focused visual style with glassmorphism, gradients, dark-mode support, reusable cards, and shared navigation components.

When changing UI:

- Reuse existing widgets before creating new ones.
- Keep feature pages clean by moving repeated UI into `widgets/`.
- Keep dark mode and current theme behavior intact.
- Match existing spacing, card shapes, gradients, and typography.
- Avoid adding new packages unless the existing toolkit cannot reasonably support the feature.

## API Configuration

The app reads the backend base URL from `lib/shared/config/api_config.dart`.

By default, the app points to the deployed backend. For local development, pass a Dart define:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

Use the same flag with other Flutter commands when needed:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

For Flutter web against the deployed Render API, keep the browser port stable:

```bash
flutter run -d chrome --web-port 57763 --dart-define=API_BASE_URL=https://vitalysync-backend.onrender.com
```

Then include the local web origin in the backend `CORS_ALLOWED_ORIGINS` setting:

```text
https://vitalysync-frontend.onrender.com,http://localhost:*,http://127.0.0.1:*
```

## Setup

Install dependencies:

```bash
flutter pub get
```

Run analysis:

```bash
flutter analyze
```

Run the app:

```bash
flutter run
```

Run widget tests:

```bash
flutter test
```

## Assets

Flutter assets are declared in `pubspec.yaml`.

```text
assets/images/
assets/animations/
```

Keep new image and animation assets organized in those folders unless a feature already has a stronger local pattern.

## Dependencies

Key frontend packages include:

- `http` for REST calls
- `shared_preferences` for local preferences and session data
- `fl_chart` for analytics charts
- `flutter_local_notifications` and `timezone` for reminders
- `geolocator` and `pedometer` for context and activity features
- `image_picker` for nutrition image input
- `lottie` and `google_fonts` for UI polish

Do not add new dependencies without checking whether an existing package already solves the problem.

## Maintenance Notes

- Keep API calls in feature data files or shared services.
- Keep reusable visual pieces in `shared/widgets` or feature-level `widgets/`.
- Keep app-wide configuration in `shared/config`.
- Keep local settings in `shared/preferences` or existing local cache helpers.
- Do not commit generated build files, crash logs, or local environment files.
