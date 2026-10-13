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
- `assessment`
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

## CBI assessment release configuration

The English CBI Personal Burnout assessment supports optional lifestyle context, offline drafts, pending submissions, and separate assessment history. Submission is enabled by default for the authorized release. Phase 3 connects Home and Dashboard to dated saved assessments and separates wellness summaries from assessment scores.

For isolated internal testing, apply backend migration `031_create_cbi_assessments.sql` through the normal migration runner on a development database and set the backend process variable `CBI_ASSESSMENT_ENABLED=true`. Then build the app with both a local API URL and the Flutter flag:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000 --dart-define=CBI_ASSESSMENT_ENABLED=true
```

`10.0.2.2` addresses the host from an Android emulator; use the appropriate host address for other targets. The account must have an age of 18 or older. Onboarding opens the assessment after profile questions; existing users open **Profile → Wellness profile → More → CBI assessment and history**.

The backend supplies all question text, response labels and versions. A previously downloaded definition supports offline retakes. Completed submissions keep their original identifier and completion time across retries; no score is calculated locally. Initial onboarding waits for server acceptance before finishing. Logout and account clearing remove local assessment drafts, pending submissions and cached results.

The release target is the Render backend and a directly installable Android APK; no Flutter web deployment is included. Backend pushes to the linked `main` branch trigger Render deployment. The production database migration was applied before the release push. `/api/health` reports the deployed revision and whether CBI is enabled; `/api/ready` checks database readiness.

Set the backend `CBI_ASSESSMENT_ENABLED=false` or build Flutter with `--dart-define=CBI_ASSESSMENT_ENABLED=false` to pause submission. Disabling the backend flag stops new definitions/submissions while preserving stored history reads. It does **not** restore legacy scoring: retired mutations return `410 LEGACY_SCORING_RETIRED` independently of the flag. New onboarding now requires the enabled CBI flow; a flag-off build cannot finish new onboarding. Previously onboarded users can log without any CBI assessment, including after a long absence.

Build the Android candidate with:

```bash
flutter build apk --release --dart-define=CBI_ASSESSMENT_ENABLED=true --dart-define=API_BASE_URL=https://vitalysync-backend.onrender.com
```

The current Android Gradle configuration uses the debug signing key even for release builds. This APK is for direct testing, not Play Store submission. Device walkthroughs, notification-upgrade checks, and the remaining Phase 4 verification are still outstanding.

Home and Dashboard offer an optional, account-scoped in-app reminder after 30 days. This is a product schedule, not a clinical interval. Dashboard plots saved observations only. Recommendation, assistant-preview, exercise, and notification caches use new policy namespaces; startup cancels the old adaptive notifications. Historical reports remain readable with a legacy-methodology label.

See [the Phase 2 API handoff](../docs/cbi-assessment-phase-2-implementation.md) and [Phase 3 integration handoff](../docs/cbi-assessment-phase-3-integration.md). The Phase 3 notes supersede Phase 2's temporary legacy fallback behavior.

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
