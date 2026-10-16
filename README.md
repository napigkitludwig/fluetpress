# FluetPress

A production-ready **Flutter client boilerplate** on a **feature-first** architecture with **MVC controllers**, offline **SQLite**, **encrypted token storage**, a **Dio** HTTP layer with JWT auto-refresh, **go_router** with an authentication guard, multi-flavor environments, and role-based access — running out of the box on **Android** and **iOS**.

It is meant to be copied and re-pointed at a real backend: swap the domain models, keep the structure, the networking layer, the session plumbing and the offline store.

---

## Table of contents

- [Features](#features)
- [Default seed credentials](#default-seed-credentials)
- [Architecture](#architecture)
- [Project structure](#project-structure)
- [Packages](#packages)
- [Prerequisites](#prerequisites)
- [Getting started](#getting-started)
- [Flavors & environment configuration](#flavors--environment-configuration)
- [Local vs. remote authentication](#local-vs-remote-authentication)
- [How the login flow works](#how-the-login-flow-works)
- [Networking](#networking)
- [Database](#database)
- [Security notes](#security-notes)
- [Extending the boilerplate](#extending-the-boilerplate)
- [Testing and analysis](#testing-and-analysis)
- [Native platform configuration](#native-platform-configuration)
- [Optional: desktop support](#optional-desktop-support)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Features

| Feature | Where |
| :--- | :--- |
| Feature-first layout (`core` / `features` / `shared`) | `lib/` |
| MVC controllers sharing a common base (loading / error / guarded run) | `lib/core/controllers/base_controller.dart` |
| Runtime environment config (`Environment` + `EnvConfig` singleton) | `lib/core/config/env_config.dart` |
| Compile-time flavors (`--dart-define`, `--dart-define-from-file`) | `lib/core/config/flavors.dart`, `config/` |
| `Dio` client: base options, bearer injection, **JWT auto-refresh**, logging | `lib/core/network/api_client.dart` |
| Typed network failures (sealed `NetworkException`) | `lib/core/network/network_exceptions.dart` |
| `Result<T>` (`Success` / `Failure`) instead of thrown exceptions | `lib/core/network/api_response.dart` |
| Centralised endpoint paths | `lib/core/network/api_endpoints.dart` |
| Connectivity watcher + offline banner | `lib/core/network/connectivity_service.dart`, `lib/shared/widgets/offline_banner.dart` |
| Encrypted token/session storage (Keystore / Keychain) | `lib/core/storage/secure_storage.dart` |
| Singleton SQLite service: schema, migrations, seeding, key/value settings | `lib/core/storage/database_helper.dart` |
| Typed local data source for accounts | `lib/features/auth/services/user_local_data_source.dart` |
| Auth service switching local SQLite ⇄ REST API | `lib/features/auth/services/auth_service.dart` |
| `go_router` routes + **auth guard** (`refreshListenable`) | `lib/app_router.dart` |
| Immutable, JSON-serialisable models via `freezed` + `json_serializable` | `lib/features/auth/models/` |
| Role-based UI (`Admin` vs `User`) | `lib/features/home/views/home_view.dart` |
| Theme system with a `ThemeExtension` and white-label `AppBrand` | `lib/core/theme/` |
| Global providers / DI container (`AppDependencies.bootstrap()`) | `lib/app.dart` |
| Reusable widgets (fields, buttons, state views, banners) | `lib/shared/widgets/` |
| Android + iOS native configuration | `android/`, `ios/` |

---

## Default seed credentials

On the **first launch** the database is created and seeded with two accounts. They exist purely so the template is demonstrable with no backend — **remove them before shipping** (see [Security notes](#security-notes)).

| Role | Default Username | Default Password |
| :--- | :--- | :--- |
| Admin | `admin_user` | `AdminPassword123!` |
| User | `standard_user` | `UserPassword123!` |

> The login screen has **Admin** and **User** shortcut buttons that fill the form with these credentials so you can try the role-based UI immediately.

---

## Architecture

Three ideas, applied consistently:

1. **Feature-first folders.** A feature owns everything it needs. `core/` is shared infrastructure and `shared/` is reusable UI. Adding a feature means adding one folder, not touching five.

2. **MVC within a feature.** Each feature has `models/` (data), `services/` (I/O), `controllers/` (state + rules) and `views/` (widgets).

3. **One-way dependencies.**

```
        features/  ──┐
                     ├──▶  core/        (config, network, storage, theme, utils)
        shared/    ──┘

        features/*  ──▶  shared/         (widgets)
        core/       ──✗─▶ features/      (never; core must stay generic)
```

```
┌──────────────────────────────┐         ┌───────────────────────────────┐
│            VIEW              │         │            MODEL              │
│  features/*/views/**         │         │  features/*/models/**         │
│  widgets only; no I/O        │         │  freezed + json_serializable  │
│  reads state, calls methods  │         │  no Flutter, no I/O           │
└──────────────┬───────────────┘         └───────────────▲───────────────┘
               │ calls                                   │ maps rows / JSON
               ▼                                         │
┌──────────────────────────────┐         ┌───────────────┴───────────────┐
│          CONTROLLER          │         │     SERVICE (I/O adapters)    │
│  features/*/controllers/**   │────────▶│  ApiClient + ApiService       │
│  ChangeNotifier; no widgets  │         │  DataSource + SecureStorage   │
└──────────────────────────────┘         │  DatabaseHelper (singleton)   │
                                         └───────────────────────────────┘
```

The rules this boilerplate enforces:

1. **Views never touch the database or the network.** A view calls methods on its controller.
2. **Controllers contain no UI.** They import `package:flutter/foundation.dart` for `ChangeNotifier` (the settings controller additionally shows `ThemeMode`) but never build widgets, and never accept a `BuildContext`.
3. **Models are data only.** `freezed` value classes with `fromJson` / `toJson`; `toMap()` is an alias of `toJson()` so a row map and a JSON body share one definition.
4. **`core/` never imports `features/`.** Services adapt the outside world; features adapt to it. The single place that names feature views is `lib/app_router.dart`, which sits *above* both `core/` and `features/` precisely because mapping URLs to screens is a composition concern.
5. **Failures are values, not exceptions.** Network and storage calls return `Result<T>`.

Data always flows **View → Controller → Service → Model → Controller → View**.

---

## Project structure

```text
lib/
├── main.dart                          # Entry point: bind, resolve flavor, bootstrap, runApp
├── app.dart                           # AppDependencies.bootstrap() + providers + MaterialApp.router
├── app_router.dart                    # AppRoute enum + GoRouter factory + auth guard
│                                      #   (composition root: the only file that names feature views)
│
├── core/                              # Shared infrastructure (never imports features/)
│   ├── config/
│   │   ├── env_config.dart            # Environment enum + EnvConfig singleton
│   │   └── flavors.dart               # FlavorConfig + compile-time switches
│   ├── controllers/
│   │   └── base_controller.dart       # isLoading / errorMessage / runGuarded()
│   ├── network/
│   │   ├── api_client.dart            # Dio + auth header + JWT refresh + logging
│   │   ├── api_endpoints.dart         # Every REST path in one place
│   │   ├── api_response.dart          # sealed Result<T> = Success<T> | Failure<T>
│   │   ├── connectivity_service.dart  # Online/offline ChangeNotifier
│   │   └── network_exceptions.dart    # sealed NetworkException hierarchy
│   ├── storage/
│   │   ├── database_helper.dart       # Singleton SQLite: schema, migrations, seeding, settings
│   │   └── secure_storage.dart        # Tokens + remembered session (Keystore / Keychain)
│   ├── theme/
│   │   ├── app_colors.dart            # Palette, AppSemanticColors extension, AppBrand
│   │   └── app_theme.dart             # Light/dark ThemeData builder
│   └── utils/
│       ├── app_constants.dart         # Branding, DB name/version, seed accounts, setting keys
│       ├── dialogs.dart               # Shared dialogs + snack bars
│       ├── extensions.dart            # String / BuildContext sugar
│       ├── password_hasher.dart       # hash() + constant-time verify()
│       └── validators.dart            # Reusable FormFieldValidators
│
├── features/                          # One folder per feature
│   ├── auth/
│   │   ├── controllers/auth_controller.dart
│   │   ├── models/
│   │   │   ├── auth_session.dart      # (+ .freezed.dart / .g.dart, generated)
│   │   │   ├── user.dart              # (+ .freezed.dart / .g.dart, generated)
│   │   │   └── user_role.dart         # enum + tolerant JsonConverter
│   │   ├── services/
│   │   │   ├── auth_api_service.dart  # REST shape of /auth/*
│   │   │   ├── auth_service.dart      # local ⇄ remote orchestration + session restore
│   │   │   └── user_local_data_source.dart
│   │   └── views/
│   │       ├── forgot_password_view.dart
│   │       ├── login_view.dart
│   │       ├── register_view.dart
│   │       └── widgets/
│   │           ├── auth_scaffold.dart
│   │           └── role_badge.dart
│   ├── home/
│   │   ├── controllers/home_controller.dart
│   │   ├── models/dashboard_summary.dart
│   │   └── views/home_view.dart
│   └── settings/
│       ├── controllers/settings_controller.dart
│       └── views/settings_view.dart
│
└── shared/
    └── widgets/                       # Reusable across features
        ├── app_button.dart            # Variants + loading state
        ├── app_text_field.dart        # Themed field + password toggle
        ├── offline_banner.dart
        └── state_views.dart           # LoadingView / EmptyView / ErrorView / AppInlineError / ResultStateView

config/                                # Flavor define-files (only *.example.json is committed)
android/                               # Android host project (Gradle / Kotlin DSL)
ios/                                   # iOS host project (Xcode + Podfile)
test/                                  # Unit tests mirroring lib/ (71 tests)
pubspec.yaml                           # Dependencies
analysis_options.yaml                  # flutter_lints rules
```

### Routes

| Path | Name | Auth |
| :--- | :--- | :--- |
| `/login` | `login` | public |
| `/register` | `register` | public |
| `/forgot-password` | `forgot-password` | public |
| `/home` | `home` | protected |
| `/settings` | `settings` | protected |

`AppRouter` redirects in both directions: signed-out users are sent to `/login`, and signed-in users are pushed off the auth screens to `/home`. Because the guard is driven by `refreshListenable: authController`, screens never check `isAuthenticated` before navigating.

---

## Packages

| Package | Why |
| :--- | :--- |
| `provider` | Supplies controllers/services to the widget tree (and re-evaluates the router guard). |
| `go_router` | Declarative routes, deep links and the authentication guard. |
| `dio` | HTTP client with interceptors (auth header, refresh, logging). |
| `pretty_dio_logger` | Readable request/response logs outside production. |
| `flutter_secure_storage` | Encrypted tokens/session — Keystore on Android, Keychain on iOS. |
| `connectivity_plus` | Drives the offline banner. |
| `freezed` + `freezed_annotation` | Immutable models, `copyWith`, unions. |
| `json_serializable` + `json_annotation` | Generated `fromJson`/`toJson` — no hand-written parsing. |
| `build_runner` | Runs the two code generators above. |
| `sqflite` + `path` | Offline store used by the local/demo auth path. |
| `crypto` | SHA-256 for the demo password hasher. |

> `flutter_dotenv` / `envied` are deliberately **not** used. They need a committed `.env` or an extra build-time file, which conflicts with "clone and run". The equivalent — secrets injected at build time and never committed — is provided by Flutter's built-in `--dart-define` / `--dart-define-from-file` and read through `EnvConfig`.

---

## Prerequisites

| Tool | Version used by this boilerplate |
| :--- | :--- |
| Flutter SDK | 3.47.x (stable) — Dart 3.13 |
| Java (JDK) | 17 |
| Android SDK | Platform 36, Build-Tools; `minSdk 24` |
| Xcode | 15+ (iOS 15 deployment target) |
| CocoaPods | 1.13+ |

```bash
flutter doctor -v
```

---

## Getting started

```bash
# 1. Dependencies
flutter pub get

# 2. (Re)generate model code. Skippable on a fresh clone — the *.freezed.dart /
#    *.g.dart outputs are committed — but required after editing a model.
dart run build_runner build

# 3. Run (pick a connected device/emulator)
flutter devices
flutter run
```

The app opens on the **login screen**. Sign in with a seeded account, or use the **Admin** / **User** shortcut buttons.

Out of the box the app uses the **offline demo store**, so it runs with no backend configured. `fluetpress.db` is created in the app sandbox on first launch and the two accounts are inserted at that moment only.

### Android

```bash
flutter emulators
flutter emulators --launch <emulator_id>     # or plug in a physical device
flutter devices

flutter run -d <device_id>

flutter build apk --debug        # build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release      # requires a signing config
flutter build appbundle --release
```

- Android SDK Platform **36** + Build-Tools installed.
- `minSdk 24` (Android 7.0). No runtime permissions are needed: SQLite lives in private storage and `flutter_secure_storage` uses the Keystore.

### iOS

```bash
sudo gem install cocoapods        # one-time

cd ios && pod install && cd ..    # also runs automatically on `flutter run`

open -a Simulator
flutter devices
flutter run -d <device_id>

flutter build ios --debug --no-codesign
flutter build ipa --release       # requires signing in Xcode
```

- macOS with Xcode 15+ and Command Line Tools.
- Deployment target **iOS 15.0**, set in both `ios/Runner.xcodeproj` (`IPHONEOS_DEPLOYMENT_TARGET`) and `ios/Podfile` (`platform :ios, '15.0'`). Keep them in sync.
- After `pod install`, open `ios/Runner.xcworkspace` (not `.xcodeproj`) to change signing or the bundle id.

---

## Flavors & environment configuration

Flavors are resolved **in Dart** from build-time defines — no Gradle product flavors or Xcode schemes are required. `Flavors.initialize()` (called first in `main()`) turns them into the `EnvConfig` singleton that the rest of the app reads.

| Define | Meaning | Default |
| :--- | :--- | :--- |
| `APP_FLAVOR` | `dev` \| `staging` \| `prod` | `dev` |
| `API_BASE_URL` | Overrides the flavor's base URL | per-flavor |
| `API_KEY` | Public API key, forwarded as a header/query by your services | empty |
| `USE_REMOTE_AUTH` | `true` → authenticate against the REST API | `false` |

Two ways to supply them:

```bash
# a) individual defines
flutter run --dart-define=APP_FLAVOR=staging

# b) a JSON define-file (recommended; keeps a whole environment in one place)
cp config/dev.example.json config/dev.json     # then edit
flutter run --dart-define-from-file=config/dev.json
flutter build appbundle --release --dart-define-from-file=config/prod.json
```

`config/*.json` is **git-ignored**; only `config/*.example.json` is committed, so client keys never land in the repository.

The active flavor, base URL, auth mode and database version are all visible at runtime in **Settings → Environment**, and a small badge on the login screen shows the flavor outside production — invaluable when someone reports "login is broken on staging".

---

## Local vs. remote authentication

`AuthService` is the only class that knows about both modes, so no controller ever branches on the environment.

| | Local mode (default) | Remote mode (`USE_REMOTE_AUTH=true`) |
| :--- | :--- | :--- |
| Credentials checked against | the SQLite `users` table | `POST /auth/login` |
| Password hashing | `PasswordHasher` (SHA-256) | the server's |
| Tokens | none | access + refresh JWT, in secure storage |
| Session restore | remembered user id in secure storage | `GET /auth/me`, refreshed on `401` |
| Password reset | unavailable (explains why) | `POST /auth/forgot-password` |

Switching is one define:

```bash
flutter run --dart-define=USE_REMOTE_AUTH=true --dart-define=API_BASE_URL=https://api.example.com/v1
```

The REST contract expected by `AuthApiService`:

```jsonc
// POST /auth/login  →  200
{
  "accessToken": "…",
  "refreshToken": "…",
  "user": { "id": 1, "username": "admin_user", "role": "Admin" }
}
```

---

## How the login flow works

The whole loop, from tap to dashboard:

1. **`LoginView`** validates the form (`Validators`) and calls `AuthController.signIn(...)`. It never touches SQLite or the network, and it does **not** navigate on success.
2. **`AuthController`** delegates to `AuthService`, which either verifies the hash against the local store or calls the API, then remembers the session in encrypted storage. The controller folds the returned `Result<AuthSession>` into its own state (`notifyListeners`).
3. **`AppRouter`** is listening (`refreshListenable: authController`). As soon as `isAuthenticated` flips, its `redirect` replaces `/login` with `/home` — the guard, not the view, performs the navigation.
4. **`HomeView`** builds a `HomeController`, which loads the account list **only** for administrators.
5. The dashboard renders the profile card plus either the **Administration** panel (create/delete accounts, live counters) or the **Standard access** panel — purely from controller state.
6. **Sign out** (from the dashboard or Settings) drops the session; the guard returns the user to `/login`.
7. If the API ever answers `401` and the refresh token is rejected, `ApiClient → AuthService.expireSession → AuthController.handleExpiredSession` clears the session and the user lands back on the login screen with an explanation — no screen has to handle it.

---

## Networking

`ApiClient` (`lib/core/network/api_client.dart`) wraps `Dio` with:

- `BaseOptions` built from `EnvConfig` (base URL, timeouts, JSON headers);
- automatic `Authorization: Bearer <token>` from secure storage, skipped for public endpoints (`authenticated: false`);
- **single-flight JWT refresh**: a `401` triggers one refresh call shared by all concurrent failures, then the original request is retried once (a `_retried` flag in `RequestOptions.extra` prevents loops);
- `pretty_dio_logger` outside production;
- typed error mapping — callers never see a `DioException`.

Every call returns a `Result<T>` instead of throwing:

```dart
final Result<List<User>> result = await apiClient.get<List<User>>(
  ApiEndpoints.users,
  decoder: ApiClient.jsonList((List<dynamic> items) => items
      .map((dynamic item) => User.fromJson(item as Map<String, dynamic>))
      .toList()),
);

switch (result) {
  case Success<List<User>>(:final List<User> data):
    return showUsers(data);
  case Failure<List<User>>(:final String message):
    return ErrorView(message: message, onRetry: loadUsers);
}
```

Typed failures (`NetworkException`) let you react precisely — `NoInternetException`, `NetworkTimeoutException`, `BadRequestException`, `UnauthorizedException`, `ForbiddenException`, `NotFoundException`, `ServerException`, `RequestCancelledException`, `UnexpectedNetworkException` — and `Failure.isUnauthorized` is a one-liner check for session expiry.

---

## Database

`DatabaseHelper` (`lib/core/storage/database_helper.dart`) is a **singleton** and the only class that opens SQLite. It owns the connection, the schema, migrations, seeding and the key/value `app_settings` table. It deliberately knows nothing about any feature: typed queries live in the feature's data source (e.g. `UserLocalDataSource`).

**Schema (version 2):**

```sql
CREATE TABLE users (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  role     TEXT NOT NULL CHECK (role IN ('Admin', 'User'))
);

CREATE TABLE app_settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

`app_settings` stores non-sensitive local preferences (the theme mode is the first one). Secrets go to `SecureStorageService` instead.

**Seeding:** on creation, if `users` is empty, the two accounts from `AppConstants` are inserted with hashed passwords. Seeding never overwrites existing data.

**Migrations:** bump `AppConstants.databaseVersion` and add the matching step to `_onUpgrade` — version 2 already demonstrates one:

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await _createSettingsTable(db);          // added in v2
  }
}
```

**Handy during development:**

```dart
await DatabaseHelper().deleteDatabaseFile(); // wipes the DB; re-seeds on next launch
await DatabaseHelper().close();
```

---

## Security notes

Read this before shipping.

**Password hashing.** `PasswordHasher` uses a **deterministic, application-wide salted SHA-256** digest so the seeded accounts work with zero native setup. That is fine for a starter template and **not production grade**. Replace `hash` / `verify` with:

- a **per-user random salt** stored alongside the hash,
- a deliberately slow KDF — **bcrypt**, **scrypt** or **Argon2id** (e.g. the `bcrypt` package),
- ideally computed off the UI isolate.

Nothing else changes: callers only depend on `PasswordHasher.hash` and `PasswordHasher.verify`.

**Also revisit for production:**

- delete the seeded accounts and the demo shortcut buttons;
- move authentication to the backend (`USE_REMOTE_AUTH=true`) so the client never verifies passwords;
- `PasswordHasher._pepper` is a compile-time constant — a real pepper must be injected per build and rotated.

**Tokens** are already handled properly: `flutter_secure_storage` writes them to the Android Keystore / iOS Keychain, and they are never written to SQLite or logs (only `pretty_dio_logger` prints bodies, and only outside production).

---

## Extending the boilerplate

Add a feature by copying the shape of an existing one. Example — a `tasks` feature.

```
lib/features/tasks/
├── controllers/task_controller.dart
├── models/task.dart           (+ generated .freezed.dart / .g.dart)
├── services/task_api_service.dart
└── views/task_list_view.dart
```

**1. Model** — `lib/features/tasks/models/task.dart`

```dart
@freezed
abstract class Task with _$Task {
  const factory Task({
    @JsonKey(includeIfNull: false) int? id,
    required String title,
    @JsonKey(name: 'user_id') required int userId,
    @Default(false) bool done,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}
```

Then `dart run build_runner build` (add `--watch` while iterating).

**2. Service** — `lib/features/tasks/services/task_api_service.dart`

```dart
class TaskApiService {
  TaskApiService({required ApiClient apiClient}) : _apiClient = apiClient;
  final ApiClient _apiClient;

  Future<Result<List<Task>>> list() => _apiClient.get<List<Task>>(
        '/tasks',
        decoder: ApiClient.jsonList(
          (List<dynamic> items) => items
              .map((dynamic item) => Task.fromJson(item as Map<String, dynamic>))
              .toList(),
        ),
      );
}
```

**3. Controller** — `lib/features/tasks/controllers/task_controller.dart`

```dart
class TaskController extends BaseController {
  TaskController({required TaskApiService apiService}) : _apiService = apiService;
  final TaskApiService _apiService;

  List<Task> _tasks = const <Task>[];
  List<Task> get tasks => List<Task>.unmodifiable(_tasks);

  Future<void> load() async {
    final Result<List<Task>> result = await _apiService.list();
    switch (result) {
      case Success<List<Task>>(:final List<Task> data):
        _tasks = data;
      case Failure<List<Task>>(:final String message):
        setError(message);
    }
    notify();
  }
}
```

**4. View** — `lib/features/tasks/views/task_list_view.dart`

A `StatefulWidget` that calls `load()` in `initState`, wraps its body in `ListenableBuilder(listenable: controller, …)`, and reuses `AppButton`, `AppTextField`, `LoadingView`, `ErrorView` and `EmptyView`.

**5. Route** — `lib/app_router.dart`

Add an `AppRoute` value and a `GoRoute`, then reach it with `context.goNamed(...)` / `context.pushNamed(...)`. Providers are already above the router, so the view can `context.read<TaskController>()` or accept one from a provider you register in `app.dart`.

### Conventions to keep it consistent

- One controller per screen or concern, extending `BaseController`.
- Controllers expose immutable state (`List.unmodifiable`) and never widgets or `BuildContext`.
- Services return `Result<T>`; they never throw at the caller (use `Result.guard` around storage calls).
- Long-lived objects are created in `AppDependencies.bootstrap()` (`app.dart`) and exposed through `provider`; screen-scoped controllers are created by their view.
- Reuse `shared/widgets/**` before writing a new widget.

---

## Testing and analysis

```bash
flutter analyze                          # zero issues out of the box (flutter_lints)
dart run build_runner build              # regenerate *.freezed.dart / *.g.dart
flutter test                             # 71 unit tests
```

Tests mirror `lib/`:

| Area | File |
| :--- | :--- |
| `User` / `UserRole` serialisation + tolerant parsing | `test/features/auth/models/user_test.dart` |
| `AuthSession` nested JSON round-trip | `test/features/auth/models/auth_session_test.dart` |
| `AuthService` (sign-in, register, restore, expiry) with in-memory fakes | `test/features/auth/services/auth_service_test.dart` |
| `DashboardSummary` counters | `test/features/home/models/dashboard_summary_test.dart` |
| `Result` / `Result.guard` | `test/core/network/api_response_test.dart` |
| `NetworkException.fromDio` mapping | `test/core/network/network_exceptions_test.dart` |
| `EnvConfig` / `Environment` / `Flavors` | `test/core/config/env_config_test.dart` |
| `PasswordHasher` | `test/core/utils/password_hasher_test.dart` |
| `Validators` | `test/core/utils/validators_test.dart` |

`AuthService` is tested against hand-written fakes (`_FakeUserStore`, `_FakeSecureStorage`) rather than the real plugins, which keeps the suite fast and device-free — the same technique works for any service you add.

> **Generated code is committed.** `*.freezed.dart` and `*.g.dart` are checked in, so a fresh clone compiles after `flutter pub get` alone. Re-run `dart run build_runner build` every time you add or change a `@freezed` / `@JsonSerializable` model. (If your team prefers a generated-code-free history, add `*.g.dart` and `*.freezed.dart` to `.gitignore` and run the builder in CI instead.)

---

## Native platform configuration

| Platform | Setting | Value | File |
| :--- | :--- | :--- | :--- |
| Android | `minSdk` | `24` (Android 7.0) | `android/app/build.gradle.kts` |
| Android | `targetSdk` / `compileSdk` | Flutter defaults (36) | `android/app/build.gradle.kts` |
| Android | Java / Kotlin JVM target | `17` | `android/app/build.gradle.kts` |
| Android | AGP / Kotlin / Gradle | 9.1.0 / 2.4.0 / 9.3.1 | `android/settings.gradle.kts`, `gradle-wrapper.properties` |
| Android | App label | `FluetPress` | `android/app/src/main/AndroidManifest.xml` |
| iOS | Deployment target | `iOS 15.0` | `ios/Runner.xcodeproj`, `ios/Podfile` |
| iOS | CocoaPods | `use_frameworks!`, Flutter pod helper | `ios/Podfile` |
| iOS | Display name | `FluetPress` | `ios/Runner/Info.plist` |

`minSdk 24` satisfies `flutter_secure_storage` and `connectivity_plus`. To change the application/bundle identifier, edit `applicationId` in `android/app/build.gradle.kts`, `PRODUCT_BUNDLE_IDENTIFIER` in Xcode, and the package declaration in `android/app/src/main/kotlin/.../MainActivity.kt`.

**Optional — native flavors.** If you want per-flavor app icons/labels or separate Play Store listings, add Gradle product flavors and Xcode schemes, then keep passing the matching `--dart-define=APP_FLAVOR=...` so Dart and native stay aligned.

---

## Optional: desktop support

Android and iOS work natively. For Windows/macOS/Linux:

1. `flutter pub add sqflite_common_ffi`
2. Register the factory at startup, after `WidgetsFlutterBinding.ensureInitialized()`:

   ```dart
   import 'dart:io';
   import 'package:sqflite_common_ffi/sqflite_ffi.dart';

   if (!Platform.isAndroid && !Platform.isIOS) {
     sqfliteFfiInit();
     databaseFactory = databaseFactoryFfi;
   }
   ```

3. `flutter create --platforms windows,macos,linux .`
4. `flutter_secure_storage` needs its desktop plugin registration (generated automatically on the next build).

`sqflite_common_ffi` pulls in `sqlite3`, which downloads/builds a native library at build time — that is why it is not a default dependency of this mobile boilerplate.

---

## Troubleshooting

| Symptom | Fix |
| :--- | :--- |
| `Target of URI doesn't exist: '.../user.freezed.dart'` | The generated files are missing (e.g. excluded from a checkout). Run `dart run build_runner build`. |
| Models behave oddly after editing one | Re-run `dart run build_runner build` (or `--watch`). |
| `flutter test` fails with *"Can't use string interpolation in a URI"* | Your project path contains `$`. Flutter's test listener mis-parses it; clone/run from a path without `$`, or create an NTFS junction (`mklink /J C:\dev\fluetpress "C:\...\fluetpress"`) and run there. |
| Login says *invalid username or password* with the seeded account | The DB is seeded only when created. Delete the app (or `deleteDatabaseFile()`) and relaunch. |
| Signed in, but every API call is `401` | Check `USE_REMOTE_AUTH` / `API_BASE_URL` — and that the backend returns `accessToken`/`refreshToken` as above. |
| Offline banner never appears | It reflects *network interfaces*, not reachability: an emulator on a host with internet looks online. |
| `minSdkVersion` error from a plugin | `minSdk` is already `24`; raise it in `android/app/build.gradle.kts` if a plugin demands more. |
| iOS pod errors / "Podfile missing" | `cd ios && pod install`; open `Runner.xcworkspace`. |
| iOS min-version warning from a pod | Keep `platform :ios, '15.0'` in sync with `IPHONEOS_DEPLOYMENT_TARGET`. |
| Android license error | `flutter doctor --android-licenses`. |
| Stale build after native changes | `flutter clean && flutter pub get`. |

---

## License

Released under the [MIT License](LICENSE).
