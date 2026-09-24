# UniFlow — Кроссплатформенное приложение расписания ТулГУ

## Архитектура проекта

```
uniflow/
├── lib/
│   ├── main.dart                    # Точка входа
│   ├── app.dart                     # Конфигурация приложения
│   │
│   ├── core/                        # Ядро приложения
│   │   ├── api/                     # API клиент
│   │   │   ├── tulsu_api.dart       # HTTP клиент
│   │   │   └── endpoints.dart       # Константы endpoints
│   │   ├── models/                  # Модели данных
│   │   │   ├── schedule.dart
│   │   │   ├── group.dart
│   │   │   ├── teacher.dart
│   │   │   ├── auditorium.dart
│   │   │   └── calendar.dart
│   │   ├── services/                # Сервисы
│   │   │   ├── storage_service.dart # Локальное хранилище
│   │   │   └── schedule_service.dart
│   │   └── theme/                   # MD3 тема
│   │       └── app_theme.dart
│   │
│   ├── features/                    # Фичи приложения
│   │   ├── schedule/                # Расписание
│   │   │   ├── screens/
│   │   │   │   ├── schedule_screen.dart
│   │   │   │   └── schedule_detail_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── schedule_card.dart
│   │   │   │   ├── day_schedule.dart
│   │   │   │   └── lesson_tile.dart
│   │   │   └── providers/
│   │   │       └── schedule_provider.dart
│   │   │
│   │   ├── search/                  # Поиск
│   │   │   ├── screens/
│   │   │   │   └── search_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── search_bar.dart
│   │   │   │   └── search_results.dart
│   │   │   └── providers/
│   │   │       └── search_provider.dart
│   │   │
│   │   └── favorites/               # Избранное
│   │       ├── screens/
│   │       │   └── favorites_screen.dart
│   │       ├── widgets/
│   │       │   └── favorite_card.dart
│   │       └── providers/
│   │           └── favorites_provider.dart
│   │
│   └── shared/                      # Общие виджеты
│       ├── widgets/
│       │   ├── loading_indicator.dart
│       │   ├── error_widget.dart
│       │   └── empty_state.dart
│       └── utils/
│           ├── date_utils.dart
│           └── extensions.dart
│
├── pubspec.yaml
├── analysis_options.yaml
└── flake.nix                        # Nix flake для сборки
```

## Tech Stack

| Компонент | Технология |
|-----------|-----------|
| Framework | Flutter 3.x |
| Язык | Dart |
| Состояние | Riverpod 2.x |
| HTTP | Dio |
| Кэширование | Hive |
| Навигация | GoRouter |
| MD3 | flutter/material.dart (native) |
| DI | Riverpod |

## Платформы

| Платформа | Статус |
|-----------|--------|
| iOS | ✅ Flutter native |
| Android | ✅ Flutter native |
| Windows | ✅ Flutter desktop |
| Linux | ✅ Flutter desktop + Nix |

## Функционал

### v1.0 — Текущий спринт
- [x] Просмотр расписания группы
- [x] Просмотр расписания преподавателя
- [x] Просмотр расписания аудитории
- [x] Поиск с автодополнением
- [x] Добавление в избранное
- [x] Локальное кэширование
- [x] Недельный/дневной вид

### v1.1 — Следующий спринт
- [ ] Уведомления о изменениях
- [ ] Календарь семестра
- [ ] Экспорт в .ics
- [ ] Widget для дома (iOS/Android)

## API Endpoints

```
Base URL: https://tulsu.ru/schedule/queries/

GET /GetDictionaries.php?term={query}
GET /GetDates.php?search_value={value}
GET /GetTimeGroups.php?search_field={field}&search_value={value}
GET /GetSchedule.php?search_field={field}&search_value={value}
GET /GetCalendar.php?search_value={value}
```

## Зависимости (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # Network
  dio: ^5.4.0
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Navigation
  go_router: ^13.0.0
  
  # UI
  flex_color_scheme: ^7.3.0
  gap: ^3.0.0
  
  # Utils
  intl: ^0.19.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  hive_generator: ^2.0.0
```

## Nix Flake (flake.nix)

```nix
{
  description = "UniFlow - TULSU Schedule App";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            flutter
            dart
            android-tools
            android-studio
          ];
          
          shellHook = ''
            echo "UniFlow dev environment loaded"
            echo "Flutter: $(flutter --version)"
          '';
        };
        
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "uniflow";
          version = "1.0.0";
          src = ./.;
          
          buildInputs = with pkgs; [
            flutter
            dart
          ];
          
          buildPhase = ''
            flutter pub get
            flutter build linux
          '';
          
          installPhase = ''
            mkdir -p $out/bin
            cp build/linux/x64/release/bundle/uniflow $out/bin/
          '';
        };
      }
    );
}
```

## Цветовая схема MD3

```dart
// Primary: #6750A4 (Purple)
// Secondary: #625B71
// Tertiary: #7D5260
// Surface: #FFFBFE
// Background: #FFFBFE
```

## Шаги реализации

1. **Инициализация проекта** — `flutter create uniflow`
2. **Настройка зависимостей** — pubspec.yaml
3. **Core слой** — API, модели, сервисы
4. **UI слой** — Экраны, виджеты
5. **State management** — Riverpod провайдеры
6. **Кэширование** — Hive
7. **Тестирование** — Unit + Widget тесты
8. **Сборка** — Nix flake + CI/CD
