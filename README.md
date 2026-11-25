# Yolo

A premium voice party room app (dark purple & gold) with the same feature set as WePlay.

| Part | Tech | Folder | Status |
|---|---|---|---|
| Mobile app | Flutter (Android first) | `app/` | In progress: Phase 1 UI on demo data |
| Backend API | PHP Laravel + MySQL | (separate, to be built) | Not started |
| Admin panel | Laravel | (later) | Not started |
| Design | Design canvas source | `design/` | 5 screens |

- **Full feature list and API contract:** [docs/FEATURES.md](docs/FEATURES.md)
- **Progress log:** [docs/PROGRESS.md](docs/PROGRESS.md)

## Run the app on your phone

Needs Flutter 3.50+ and Android Studio (Android SDK) on your computer.

```bash
git clone https://github.com/zirango-in/Yolo.git
cd Yolo
git checkout develop
cd app
flutter pub get
flutter run            # with your Android phone connected (USB debugging on)
flutter build apk      # APK at app/build/app/outputs/flutter-apk/app-release.apk
```

The app runs on built-in **demo data** until the Laravel API exists. To use the API:

```bash
flutter run --dart-define=DEMO=false --dart-define=API_URL=https://your-server.com/api/v1
```

## App structure

```
app/lib/
  core/       config (demo vs API), theme (colors, fonts, transitions)
  data/       models, repository (DemoRepository + ApiRepository for Laravel), state providers
  features/   auth, home, room (seats, chat, gifts), profile
  widgets/    shared premium widgets (avatar with speaking glow, gold buttons, coin pill)
```
