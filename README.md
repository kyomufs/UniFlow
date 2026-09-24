<div align="center">

# UniFlow

**Cross-platform schedule companion for Tula State University students**

[![Build Android APK](https://github.com/kyomufs/UniFlow/actions/workflows/android-build.yml/badge.svg)](https://github.com/kyomufs/UniFlow/actions/workflows/android-build.yml)
[![Build iOS IPA](https://github.com/kyomufs/UniFlow/actions/workflows/ios-build.yml/badge.svg)](https://github.com/kyomufs/UniFlow/actions/workflows/ios-build.yml)
[![Release](https://github.com/kyomufs/UniFlow/actions/workflows/release.yml/badge.svg)](https://github.com/kyomufs/UniFlow/actions/workflows/release.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.4-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Material Design 3](https://img.shields.io/badge/Material%20Design-3-6750A4)](https://m3.material.io)

</div>

UniFlow turns the open TulSU schedule API into a fast, local-first mobile
app: live schedule with a change journal, subject notes, grades and task
tracking — all wrapped in a Material You (MD3) UI with dynamic theming.

## Features

- 📅 **Schedule** — live timetable from the open TulSU API, weekly/day view,
  groups, teachers, and offline cache; built-in demo mode without a network
- 🔄 **Change journal** — field-level diff of schedule updates
  (what changed, when, and what it was before), grouped by day
- 📝 **Notes** — per-subject notebooks with subfolders and rich structure
- 🎯 **Tasks** — status, priority, due dates and grades per subject
- 📊 **Grades** — performance tracking with statistics
- 🎨 **Material You** — dynamic color from a seed color, light/dark themes,
  M3 components (NavigationBar, SegmentedButton, Fitted type scale)
- 🔔 **Notifications** — alerts for schedule changes
- 📴 **Local-first** — Hive storage, no account required

## Platforms

| Android | iOS | Web | Windows | Linux |
|:---:|:---:|:---:|:---:|:---:|
| ✅ | ✅ | ✅ | ✅ | ✅ |

## Getting started

### Prerequisites

- Flutter **3.47.4** (or just [Nix](https://nixos.org/download/): the flake
  pins the whole toolchain)

### Run

```bash
cd uniflow
flutter pub get
flutter run            # or: flutter run -d chrome / windows / linux
```

With Nix the toolchain comes from the repo:

```bash
nix develop             # Flutter + JDK pinned by flake.lock
cd uniflow && flutter run
```

### Build releases locally

```bash
flutter build apk --release     # build/app/outputs/flutter-apk/app-release.apk
flutter build ios --release     # requires macOS + Xcode
```

## CI/CD

GitHub Actions builds both platforms on every push to `main`:

| Workflow | Trigger | Result |
|---|---|---|
| `android-build.yml` | push to `main`, PRs | tests + downloadable APK artifact |
| `ios-build.yml` | push to `main` | tests-free unsigned IPA artifact |
| `release.yml` | tag `v*` | **GitHub Release** with `UniFlow-<tag>.apk` and `UniFlow-<tag>.ipa` |

Cut a release:

```bash
git tag -a v1.1.0 -m "UniFlow v1.1.0"
git push origin v1.1.0
```

## Project structure

```
uniflow/
├── lib/
│   ├── core/                 # theme, storage, notifications, models
│   ├── features/
│   │   ├── schedule/         # timetable + change journal
│   │   ├── notes/            # subjects, subfolders, tasks
│   │   ├── performance/      # grades & statistics
│   │   └── profile/          # settings, onboarding
│   └── app.dart              # shell + navigation
├── test/                     # unit & widget tests
├── android/  ios/  web/  windows/  linux/
└── pubspec.yaml
```

## Design

UniFlow follows [Material Design 3](https://m3.material.io):

- color roles come from `ColorScheme.fromSeed()` (no hard-coded surfaces)
- tonal surfaces instead of elevation shadows
- MD3 components (`NavigationBar`, `SegmentedButton`, cards, dialogs)
