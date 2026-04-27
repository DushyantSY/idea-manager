# 💡 Idea Manager — Flutter Android App

A lightweight, privacy-focused, **fully offline** personal idea management app.
Capture ideas, evaluate them with pros/cons and ratings, organise with tags,
and convert them into actionable tasks — all stored locally on your device.

---

## 📱 Screenshots (UI Description)

| Screen | Description |
|---|---|
| **Splash** | Purple gradient with lightbulb icon + animated scale-in |
| **Home (Ideas List)** | Searchable card list with status chips, priority icons, star ratings, tags. FAB to add new idea. Sort/filter drawer. |
| **Add / Edit Idea** | Full scrollable form: title, description, status dropdown, priority dropdown, star picker, category, tag chips, pros/cons lists, notes |
| **Idea Detail** | Read-only rich view: evaluation section, pros/cons, linked tasks list, "Add Task" FAB |
| **Tasks Screen** | Grouped task list (To-Do → In Progress → Done), tap circle to cycle status, filter chips at top |
| **Settings** | Dark mode toggle, Export JSON/CSV, Reset with confirmation dialog |

---

## 🏗️ Architecture

```
lib/
├── main.dart                      ← Entry point (ProviderScope, DB warm-up)
├── app.dart                       ← MaterialApp + theme switching + routes
│
├── core/
│   ├── constants/app_constants.dart   ← DB names, table names, keys
│   ├── theme/app_theme.dart           ← Material 3 light + dark themes
│   └── utils/app_utils.dart           ← Date formatting + JSON/CSV export
│
├── data/
│   ├── database/database_helper.dart  ← SQLite singleton (sqflite)
│   ├── models/
│   │   ├── idea_model.dart            ← IdeaModel + IdeaStatus + Priority enums
│   │   └── task_model.dart            ← TaskModel + TaskStatus enum
│   └── repositories/
│       └── idea_repository.dart       ← IdeaRepository + TaskRepository
│
└── presentation/
    ├── providers/providers.dart       ← All Riverpod providers + notifiers
    ├── screens/
    │   ├── splash_screen.dart
    │   ├── home_screen.dart
    │   ├── add_edit_idea_screen.dart
    │   ├── idea_detail_screen.dart
    │   ├── tasks_screen.dart
    │   └── settings_screen.dart
    └── widgets/widgets.dart           ← IdeaCard, TaskCard, PriorityBadge,
                                         StarRating, ProsConsSection, TagInput…
```

### Data Flow

```
UI Screen
  └─ watches/reads Riverpod Provider
        └─ calls Repository method
              └─ calls DatabaseHelper (sqflite)
                    └─ SQLite on device storage
```

---

## 📦 Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^2.4.9 | State management (providers, notifiers) |
| `sqflite` | ^2.3.0 | Local SQLite database |
| `path_provider` | ^2.1.2 | App-safe file paths |
| `path` | ^1.9.0 | Path join utilities |
| `uuid` | ^4.3.3 | Unique ID generation for records |
| `intl` | ^0.19.0 | Date formatting |
| `shared_preferences` | ^2.2.2 | Lightweight settings persistence |
| `google_fonts` | ^6.2.1 | Inter font family |
| `flutter_slidable` | ^3.0.1 | Swipe-to-action on list items |
| `share_plus` | ^7.2.2 | Native share sheet for export files |
| `csv` | ^6.0.0 | CSV generation for export |

---

## 🛠️ Build Instructions

### Prerequisites

1. **Flutter SDK** ≥ 3.16.0  
   → [Install Flutter](https://docs.flutter.dev/get-started/install)

2. **Android SDK** (via Android Studio or command-line tools)  
   → [Install Android Studio](https://developer.android.com/studio)

3. **Java 17** (required by Gradle 8.x)  
   → Check: `java -version`

4. **Connected Android device** OR **Android Emulator** (API 21+)

---

### Step 1 — Clone / Extract the project

```bash
# If you received a zip:
unzip idea_manager.zip -d idea_manager
cd idea_manager

# Verify Flutter is installed:
flutter --version
```

---

### Step 2 — Install dependencies

```bash
flutter pub get
```

---

### Step 3 — Run in development (hot reload)

```bash
# List connected devices
flutter devices

# Run on connected device or emulator
flutter run

# Run on specific device
flutter run -d <device-id>
```

---

### Step 4 — Build a debug APK

```bash
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

---

### Step 5 — Build a release APK (unsigned)

```bash
flutter build apk --release --split-per-abi
```

This produces **3 smaller APKs** split by CPU architecture:
```
build/app/outputs/flutter-apk/
  app-armeabi-v7a-release.apk   ← 32-bit ARM (older phones)
  app-arm64-v8a-release.apk     ← 64-bit ARM (modern phones) ← use this
  app-x86_64-release.apk        ← x86 emulators
```

For a single universal APK:
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

---

### Step 6 — Build an Android App Bundle (AAB) for Play Store

```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

---

### Step 7 — Install APK on your phone

#### Option A — ADB (USB cable)
```bash
# Enable Developer Options + USB Debugging on your phone first
adb devices                                    # Verify device is listed
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

#### Option B — Direct transfer
1. Copy the APK to your phone (USB, email, Google Drive, etc.)
2. On your phone, open a file manager and tap the APK
3. Allow "Install from unknown sources" when prompted
4. Tap **Install**

---

### Step 8 — Sign the release APK (for distribution)

```bash
# 1. Generate a keystore (one-time)
keytool -genkey -v \
  -keystore ~/idea-manager-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias idea-manager

# 2. Create android/key.properties (DO NOT commit this file!)
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=idea-manager
storeFile=<path-to>/idea-manager-key.jks

# 3. Add signing config to android/app/build.gradle (see comments there)
# 4. Build signed APK
flutter build apk --release
```

---

## 🎨 Customisation

### Change App Name
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
android:label="My Ideas"
```

### Change Package ID
Edit `android/app/build.gradle`:
```groovy
applicationId "com.yourname.ideamanager"
```
And update the Kotlin package path accordingly.

### Change Brand Colour
Edit `lib/core/theme/app_theme.dart`:
```dart
static const Color _primaryLight = Color(0xFF6750A4); // ← your colour
```

### Enable Firebase Cloud Sync (Optional)
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add `firebase_core` and `cloud_firestore` to `pubspec.yaml`
3. Create a `FirebaseIdeaRepository` that implements the same interface
4. Toggle between local and Firebase via a provider

---

## 🔒 Privacy

- **No internet permission** — network is not used by default
- **No analytics or tracking**
- **No ads**
- **All data stored locally** in SQLite at `/data/data/<package>/databases/`
- Export is opt-in and shared via the system share sheet (you control where it goes)

---

## 🚀 Future Improvements

1. **Widgets** — Home screen widget showing your top-priority idea
2. **Notifications** — Task due-date reminders via local notifications
3. **Firebase Sync** — Optional cloud backup / multi-device sync
4. **Idea templates** — Pre-fill form fields for common idea types
5. **Kanban board view** — Drag-and-drop idea cards between columns
6. **Attach images** — Photo from camera/gallery attached to an idea
7. **Voice input** — Quick-capture via speech-to-text
8. **Recurring tasks** — Repeat daily/weekly tasks
9. **Statistics screen** — Charts: ideas by status, tasks completed per week
10. **Import** — Re-import previously exported JSON to restore data
11. **iPad / tablet layout** — Master-detail split view
12. **Biometric lock** — Fingerprint / Face ID protection

---

## 📝 Troubleshooting

| Error | Fix |
|---|---|
| `flutter pub get` fails | Run `flutter upgrade` then retry |
| `sdk 'android-xx' not found` | Open Android Studio → SDK Manager → install the required API level |
| Build fails with Gradle error | Ensure Java 17: `java -version`. Set `JAVA_HOME` correctly |
| APK installs but crashes | Run `flutter run` in debug mode and check console for errors |
| `adb: device not found` | Enable USB Debugging; try a different USB cable |

---

## 📄 License

MIT — free to use, modify, and self-host.
