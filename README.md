# FluetPress

A production-ready **Flutter starter template** built on a strict **MVC (Model–View–Controller)** architecture, with an embedded **SQLite** database and **role-based authentication**, running out of the box on **Android** and **iOS**.

It is designed to be copied and re-used as the foundation of any new Flutter app: swap the domain model, keep the structure, the database service and the role plumbing.

---

## Table of contents

- [Features](#features)
- [Default seed credentials](#default-seed-credentials)
- [Architecture — strict MVC](#architecture--strict-mvc)
- [Project structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Getting started](#getting-started)
  - [Android](#android)
  - [iOS](#ios)
- [Native platform configuration](#native-platform-configuration)
- [How the login flow works](#how-the-login-flow-works)
- [Database](#database)
- [Security notes on password hashing](#security-notes-on-password-hashing)
- [Extending the template](#extending-the-template)
- [Optional: desktop support](#optional-desktop-support)
- [Testing and analysis](#testing-and-analysis)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Features

| Feature | Where |
| :--- | :--- |
| Strict MVC separation (models / controllers / views) | `lib/models`, `lib/controllers`, `lib/views` |
| Singleton SQLite service with `toMap()` / `fromMap()` entities | `lib/services/database_helper.dart`, `lib/models/user.dart` |
| Auto-seeded default accounts on first launch | `DatabaseHelper._seedDefaults` |
| SHA-256 password hashing (swappable) | `lib/services/password_service.dart` |
| Role-based UI (`Admin` vs `User`) | `lib/views/home/home_view.dart` |
| Login screen authenticating against SQLite | `lib/views/auth/login_view.dart` |
| Centralised theme (light + dark, Material 3) | `lib/utils/app_theme.dart` |
| Global named routes + controller injection | `lib/utils/app_routes.dart`, `lib/app.dart` |
| Reusable base controller (loading / error / guarded execution) | `lib/controllers/base_controller.dart` |
| Android + iOS native configuration | `android/`, `ios/` |

---

## Default seed credentials

On the **first launch** the database is created and seeded with these two accounts. They are intended for development/template purposes only — see [Security notes](#security-notes-on-password-hashing).

| Role | Default Username | Default Password |
| :--- | :--- | :--- |
| Admin | `admin_user` | `AdminPassword123!` |
| User | `standard_user` | `UserPassword123!` |

> The login screen also has **Admin** and **User** shortcut buttons that fill the form with these credentials so you can try the role-based UI immediately.

---

## Architecture — strict MVC

```
┌───────────────────────────────┐        ┌────────────────────────────┐
│             VIEW              │        │          MODEL             │
│  (lib/views/**, widgets only) │        │  (lib/models/**)           │
│                               │        │  plain Dart + toMap/fromMap│
│  • render state               │        │  no Flutter, no I/O        │
│  • forward user intent        │        └─────────────▲──────────────┘
└───────────────┬───────────────┘                      │
                │ calls                                │ maps rows
                ▼                                      │
┌───────────────────────────────┐        ┌─────────────┴──────────────┐
│          CONTROLLER           │        │      SERVICE (persistence) │
│  (lib/controllers/**)         │───────▶│  DatabaseHelper (singleton)│
│  ChangeNotifier + business    │        │  + PasswordService         │
│  rules; NO widget code        │        │  lib/services/**           │
└───────────────────────────────┘        └────────────────────────────┘
```

The rules the template enforces:

1. **Views never touch the database.** A view may only call methods on its controller. `lib/views/**` imports nothing from `lib/services/**`.
2. **Controllers contain no UI.** `lib/controllers/**` imports `package:flutter/foundation.dart` (for `ChangeNotifier`) but never `package:flutter/material.dart`. No `Widget`, `BuildContext` or `Navigator` appears in a controller.
3. **Models are data only.** Plain Dart objects with `toMap()` and `fromMap`, plus table/column name constants. No business logic, no Flutter imports.
4. **Services own I/O.** `DatabaseHelper` is the single place that knows SQL.

Data always flows **View → Controller → Service → Model → Controller → View**.

---

## Project structure

```text
lib/
├── main.dart                     # Entry point: init DB, run the app
├── app.dart                      # MaterialApp: theme, routes, shared controllers
│
├── controllers/                  # Business logic & state (no widgets)
│   ├── base_controller.dart      # ChangeNotifier base: isLoading, errorMessage, runGuarded()
│   ├── auth_controller.dart      # Login / logout, current user, session state
│   └── home_controller.dart      # Dashboard state + admin-only actions
│
├── models/                       # Plain Dart data structures
│   ├── user.dart                 # User entity + toMap()/fromMap()
│   └── user_role.dart            # UserRole enum ('Admin' | 'User')
│
├── services/                     # Infrastructure / I/O
│   ├── database_helper.dart      # Singleton SQLite service (create, seed, CRUD)
│   └── password_service.dart     # Hashing + verification
│
├── utils/                        # Cross-cutting helpers
│   ├── app_constants.dart        # Branding, DB name/version, seed credentials
│   ├── app_routes.dart           # Route names + AppRouter (controller injection)
│   ├── app_theme.dart            # Light/dark ThemeData
│   └── validators.dart           # Reusable form validators
│
└── views/                        # UI screens and widgets (no database access)
    ├── auth/
    │   └── login_view.dart       # Login screen
    ├── home/
    │   └── home_view.dart        # Dashboard with role-based variations
    └── shared/
        └── widgets/
            ├── app_text_field.dart   # Themed text field (with password toggle)
            ├── primary_button.dart   # CTA button with loading state
            └── role_badge.dart       # Colour-coded role pill

android/                          # Android host project (Gradle / Kotlin DSL)
ios/                              # iOS host project (Xcode + Podfile)
test/                             # Unit tests for models, services and validators
pubspec.yaml                      # Dependencies
analysis_options.yaml             # flutter_lints rules
```

---

## Prerequisites

| Tool | Version used by this template |
| :--- | :--- |
| Flutter SDK | 3.47.x (stable) — Dart 3.13 |
| Java (JDK) | 17 |
| Android SDK | Platform 36, Build-Tools; `minSdk 24` |
| Xcode | 15+ (iOS 15 deployment target) |
| CocoaPods | 1.13+ |

Verify your setup:

```bash
flutter doctor -v
```

---

## Getting started

```bash
# 1. Get dependencies
flutter pub get

# 2. Run (pick a connected device/emulator)
flutter devices
flutter run
```

The app opens on the **login screen**. Use one of the seeded accounts (or the Admin / User shortcut buttons).

The database file (`fluetpress.db`) is created on first launch inside the app's sandbox; the two accounts are inserted at that moment only.

### Android

```bash
# List emulators / devices
flutter emulators
flutter emulators --launch <emulator_id>     # or plug in a physical device
flutter devices

# Run
flutter run -d <device_id>

# Build artefacts
flutter build apk --debug        # build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release      # requires a signing config (see android/app/build.gradle.kts)
flutter build appbundle --release
```

Requirements:

- Android SDK Platform **36** and Build-Tools installed (`flutter doctor` checks this).
- `minSdk 24` (Android 7.0), `targetSdk`/`compileSdk` follow the Flutter SDK defaults (36).
- No runtime permissions are needed — SQLite lives in the app's private storage.

### iOS

```bash
# One-time: install CocoaPods if you do not have it
sudo gem install cocoapods

# Install/refresh pods (also runs automatically on `flutter run`)
cd ios && pod install && cd ..

# Run on a simulator or device
open -a Simulator                # boot a simulator
flutter devices
flutter run -d <device_id>

# Build artefacts
flutter build ios --debug --no-codesign
flutter build ipa --release      # requires signing in Xcode
```

Requirements:

- macOS with Xcode 15+ and the Command Line Tools (`xcode-select --install`).
- Deployment target **iOS 15.0** — set in both `ios/Runner.xcodeproj` (`IPHONEOS_DEPLOYMENT_TARGET`) and `ios/Podfile` (`platform :ios, '15.0'`). Keep the two in sync.
- Open `ios/Runner.xcworkspace` (not `.xcodeproj`) after `pod install` for signing/bundle-id changes.

---

## Native platform configuration

| Platform | Setting | Value | File |
| :--- | :--- | :--- | :--- |
| Android | `minSdk` | `24` (Android 7.0) | `android/app/build.gradle.kts` |
| Android | `targetSdk` / `compileSdk` | Flutter defaults (36) | `android/app/build.gradle.kts` |
| Android | Java / Kotlin JVM target | `17` | `android/app/build.gradle.kts` |
| Android | AGP / Kotlin / Gradle | 9.1.0 / 2.4.0 / 9.3.1 | `android/settings.gradle.kts`, `android/gradle/wrapper/gradle-wrapper.properties` |
| Android | App label | `FluetPress` | `android/app/src/main/AndroidManifest.xml` |
| iOS | Deployment target | `iOS 15.0` | `ios/Runner.xcodeproj`, `ios/Podfile` |
| iOS | CocoaPods | `use_frameworks!`, Flutter pod helper | `ios/Podfile` |
| iOS | Display name | `FluetPress` | `ios/Runner/Info.plist` |

To change the application/bundle identifier, edit `applicationId` in `android/app/build.gradle.kts`, `PRODUCT_BUNDLE_IDENTIFIER` in Xcode, and the package declaration in `android/app/src/main/kotlin/.../MainActivity.kt`.

---

## How the login flow works

A single example of the whole loop, from tap to dashboard:

1. **`LoginView`** (view) collects the username/password and runs only form validation (`Validators`).
2. It calls `AuthController.login(username:, password:)` — the view knows nothing about SQLite.
3. **`AuthController`** (controller) asks `DatabaseHelper.getUserByUsername(...)`, then calls `PasswordService.verify(...)` to compare the hash. On success it stores `currentUser` and notifies its listeners; on failure it sets a human-readable `errorMessage`.
4. The **view** rebuilds via `ListenableBuilder`, shows the error banner if needed, and navigates to `AppRoutes.home` on success.
5. **`HomeView`** builds a `HomeController`, which — only when the role is `Admin` — loads the account list through `DatabaseHelper.getUsers()`.
6. The dashboard renders the profile card plus either the **Administration** panel (Admin) or the **Standard access** panel (User), purely from controller state.

---

## Database

`DatabaseHelper` (`lib/services/database_helper.dart`) is a **singleton** and the only class that talks to SQLite.

**Schema (version 1):**

```sql
CREATE TABLE users (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  role     TEXT NOT NULL CHECK (role IN ('Admin', 'User'))
);
```

**Seeding:** on creation, if the table is empty, the two accounts from `AppConstants` are inserted with hashed passwords. Seeding never overwrites existing data.

**Changing the schema / migrations:** bump `AppConstants.databaseVersion` and add the step to `DatabaseHelper._onUpgrade`, e.g.

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('ALTER TABLE ${User.tableName} ADD COLUMN email TEXT');
  }
}
```

**Handy during development** (call from a controller/test):

```dart
await DatabaseHelper().deleteDatabaseFile(); // wipes the DB, re-seeds on next launch
await DatabaseHelper().close();
```

---

## Security notes on password hashing

`PasswordService` currently uses a **deterministic, application-wide salted SHA-256** digest (`crypto` package). This keeps the template dependency-light and makes the seed accounts work with zero setup. **It is not production-grade.**

Before shipping, replace `PasswordService.hash` / `verify` with:

- a **per-user random salt** (stored alongside the hash),
- a deliberately slow KDF — **bcrypt**, **scrypt** or **Argon2id** (e.g. the `bcrypt` package),
- ideally computed off the UI isolate.

Nothing else in the codebase changes, because controllers only depend on `PasswordService.hash` and `PasswordService.verify`.

Other template defaults to revisit for production: the seeded accounts, the demo credential shortcut buttons, and the in-memory-only session (there is no "remember me" token).

---

## Extending the template

The fastest way to add a feature is to copy the `User` slice. Example — adding a `Task` entity.

### 1. Model — `lib/models/task.dart`

```dart
class Task {
  const Task({this.id, required this.title, required this.userId});

  static const String tableName = 'tasks';
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnUserId = 'user_id';

  final int? id;
  final String title;
  final int userId;

  factory Task.fromMap(Map<String, Object?> map) => Task(
        id: map[columnId] as int?,
        title: map[columnTitle] as String,
        userId: map[columnUserId] as int,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        if (id != null) columnId: id,
        columnTitle: title,
        columnUserId: userId,
      };
}
```

### 2. Table — `lib/services/database_helper.dart`

Add the `CREATE TABLE` statement in `_onCreate` (and a migration in `_onUpgrade` if the DB already shipped), then add `getTasks` / `insertTask` / `deleteTask` methods following the existing `User` queries.

### 3. Controller — `lib/controllers/task_controller.dart`

```dart
class TaskController extends BaseController {
  TaskController({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;
  List<Task> _tasks = const <Task>[];
  List<Task> get tasks => List<Task>.unmodifiable(_tasks);

  Future<void> load() async {
    final List<Task>? result = await runGuarded(_databaseHelper.getTasks);
    if (result != null) {
      _tasks = result;
      notify();
    }
  }
}
```

`runGuarded` gives you loading/error handling for free; `isLoading` and `errorMessage` are already exposed to views.

### 4. View — `lib/views/tasks/task_list_view.dart`

Create a `StatefulWidget` that owns a `TaskController`, calls `load()` in `initState`, and wraps its body in:

```dart
ListenableBuilder(
  listenable: controller,
  builder: (context, _) => /* widgets driven by controller state */,
)
```

Use `AppTextField`, `PrimaryButton` and `RoleBadge` from `lib/views/shared/widgets/` to stay consistent.

### 5. Route — `lib/utils/app_routes.dart`

Add a constant and a case in `AppRouter.onGenerateRoute`, injecting whatever controller the view needs.

### Conventions to keep the template consistent

- One controller per screen (or per concern), extending `BaseController`.
- Controllers expose immutable views of their state (`List.unmodifiable`) and never widgets.
- Views read state and call methods — they never import `lib/services/**`.
- Business rules (validation beyond form format, permissions, hashing) live in controllers/services, not widgets.
- Register long-lived controllers in `app.dart`; screen-scoped ones are created by their view.

---

## Optional: desktop support

The template targets Android and iOS, where `sqflite` works natively with no extra setup. To also run on Windows / macOS / Linux:

1. Add the FFI implementation: `flutter pub add sqflite_common_ffi`
2. Register it once at startup (in `main()`, after `WidgetsFlutterBinding.ensureInitialized()`):

   ```dart
   import 'dart:io';
   import 'package:sqflite_common_ffi/sqflite_ffi.dart';

   if (!Platform.isAndroid && !Platform.isIOS) {
     sqfliteFfiInit();
     databaseFactory = databaseFactoryFfi;
   }
   ```

3. Generate the desktop folders: `flutter create --platforms windows,macos,linux .`

Because `sqflite_common_ffi` pulls in the `sqlite3` package (which builds/downloads a native library at build time), it is intentionally **not** a dependency of this mobile template.

---

## Testing and analysis

```bash
flutter analyze     # zero issues out of the box (flutter_lints)
flutter test        # unit tests for models, services and validators
```

The shipped tests cover `User`/`UserRole` serialisation, `PasswordService` hashing/verification and the form validators — the pure-Dart layers that are cheap to test. Add widget tests as you build screens; inject fake controllers so views stay testable without a database.

---

## Troubleshooting

| Symptom | Fix |
| :--- | :--- |
| `Target of URI doesn't exist` after cloning | Run `flutter pub get`. |
| iOS build fails with "Podfile missing" / pod errors | `cd ios && pod install`; ensure CocoaPods is installed and open `Runner.xcworkspace`. |
| iOS min-version warning from a pod | Keep `platform :ios, '15.0'` in `ios/Podfile` and `IPHONEOS_DEPLOYMENT_TARGET` in sync. |
| `minSdkVersion` error from a plugin | `minSdk` is already `24`; raise it in `android/app/build.gradle.kts` if a plugin demands more. |
| Seed accounts missing | The DB is seeded only when created. Delete the app (or `deleteDatabaseFile()`) and relaunch. |
| Android license error | `flutter doctor --android-licenses`. |
| Stale build after changing native config | `flutter clean && flutter pub get`. |

---

## License

Released under the [MIT License](LICENSE).
