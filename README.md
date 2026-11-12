# Flutter Voters App

Mobile app for voter outreach (“Friend Banking”): contacts, personal/community impact goals, message templates, and captain leaderboards.

Built with **Flutter** and **MVC + Provider** for clear separation of UI, state, and data access.

## Features

- Login with persisted session
- Impact dashboard (personal goal + community Plan 777)
- Contacts list with search, categories, and detail flows
- Message templates
- Captain leaderboard
- Profile / account / about / terms

## Architecture

**MVC + Provider**

| Layer | Location | Role |
|--------|----------|------|
| **Model** | `lib/models/` | API response DTOs and UI models (e.g. `UiContact`) |
| **View** | `lib/views/` | Screens and widgets (UI only for core flows) |
| **Controller** | `lib/controllers/` | `ChangeNotifier`s with business/async logic |
| **Service** | `lib/services/` | `ApiService`, `AuthStorage`, helpers |

Core flows fully on Provider:

- `AuthController` — login / logout / session
- `HomeController` — bottom tabs + profile sheet
- `ContactsController` — contacts list, search, refresh
- `ImpactController` — personal goal, voter impact, Plan 777

Other screens live under `lib/views/` and still call services directly; they can be moved onto controllers later.

```
lib/
  main.dart                 # MultiProvider + MaterialApp
  controllers/
  models/
  views/
  services/
```

## Tech stack

- Flutter / Dart
- Provider (state management)
- `http`, `shared_preferences`, `sqflite`
- `flutter_contacts`, `geolocator`, `url_launcher`, `image_picker`, `shimmer`, `google_fonts`

## Getting started

### 1. Clone

```bash
git clone https://github.com/umarfarooq21/FlutterVotersApp.git
cd FlutterVotersApp
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run

```bash
flutter run
```

## Build release

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

## Requirements

- Flutter SDK (see `environment.sdk` in `pubspec.yaml`)
- Android Studio / Xcode as needed for your target
