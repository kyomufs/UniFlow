# UniFlow — Итоговый отчёт

## Что было сделано

### 1. Исследование API расписания ТулГУ

✅ **Полностью открытый PHP API** без авторизации

| Endpoint | Назначение |
|----------|-----------|
| `GetDictionaries.php` | Автодополнение (группы, преподаватели, аудитории) |
| `GetDates.php` | Диапазон дат расписания |
| `GetTimeGroups.php` | Временные слоты (пары) |
| `GetSchedule.php` | Основное расписание (JSON) |
| `GetCalendar.php` | Учебный календарь |

**Вывод:** API идеально подходит для создания приложения — структурированные JSON-данные, нет авторизации, минимальная нагрузка.

---

### 2. Создано кроссплатформенное приложение

#### Tech Stack
- **Flutter 3.x** — кроссплатформенный фреймворк
- **Riverpod** — управление состоянием
- **Dio** — HTTP клиент
- **Hive** — локальное хранилище
- **GoRouter** — навигация
- **Flex Color Scheme** — Material Design 3

#### Поддерживаемые платформы
- ✅ iOS
- ✅ Android
- ✅ Windows
- ✅ Linux (Arch + NixOS)
- ✅ Web

---

### 3. Структура проекта

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
│   │   │   └── schedule.dart
│   │   ├── services/                # Сервисы
│   │   │   ├── storage_service.dart # Локальное хранилище
│   │   │   └── schedule_service.dart
│   │   └── theme/                   # MD3 тема
│   │       └── app_theme.dart
│   │
│   ├── features/                    # Фичи приложения
│   │   ├── schedule/                # Расписание
│   │   │   ├── screens/
│   │   │   │   └── schedule_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── lesson_tile.dart
│   │   │   │   └── day_schedule.dart
│   │   │   └── providers/
│   │   │       └── schedule_provider.dart
│   │   │
│   │   ├── search/                  # Поиск
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
│       └── widgets/
│           ├── loading_indicator.dart
│           └── error_widget.dart
│
├── pubspec.yaml
├── analysis_options.yaml
├── flake.nix                        # Nix flake для сборки
├── README.md
└── .gitignore
```

---

### 4. Реализованный функционал

#### API клиент (`core/api/tulsu_api.dart`)
- ✅ Поиск групп, преподавателей, аудиторий
- ✅ Получение расписания
- ✅ Получение учебного календаря
- ✅ Обработка ошибок

#### Модели данных (`core/models/schedule.dart`)
- ✅ `ScheduleItem` — пара (урок)
- ✅ `GroupInfo` — информация о группе
- ✅ `LessonType` — тип занятия (лекция/практика/лабораторная)
- ✅ `SearchResult` — результат поиска
- ✅ `ScheduleState` — состояние расписания

#### Сервисы (`core/services/`)
- ✅ `StorageService` — локальное хранилище (Hive)
- ✅ `ScheduleService` — бизнес-логика расписания

#### UI компоненты

**Экран расписания (`schedule_screen.dart`)**
- ✅ Просмотр расписания группы/преподавателя/аудитории
- ✅ Недельный и дневной вид
- ✅ Pull-to-refresh
- ✅ Поиск с автодополнением

**Экран избранного (`favorites_screen.dart`)**
- ✅ Группировка по типам (группы/преподаватели/аудитории)
- ✅ Добавление/удаление из избранного
- ✅ Очистка избранного

**Виджеты**
- ✅ `LessonTile` — карточка пары
- ✅ `DaySchedule` — расписание на день
- ✅ `FavoriteCard` — карточка избранного
- ✅ `LoadingIndicator` — индикатор загрузки
- ✅ `ErrorWidget` — виджет ошибки

#### Состояние приложения (Riverpod)
- ✅ `ScheduleNotifier` — управление расписанием
- ✅ `SearchNotifier` — управление поиском
- ✅ `FavoritesNotifier` — управление избранным

#### Тема Material Design 3
- ✅ Светлая и тёмная тема
- ✅ Цвета для типов занятий
- ✅ Градиенты для карточек
- ✅ Адаптивная типографика

---

### 5. Сборка для Linux

#### NixOS (`flake.nix`)
```bash
# Вход в dev shell
nix develop

# Сборка пакета
nix build
```

#### Arch Linux
```bash
# Установка зависимостей
sudo pacman -S flutter dart gtk3 glib pango cairo gdk-pixbuf atk epoxy

# Запуск
flutter run -d linux
```

---

## Запуск проекта

### Установка Flutter

```bash
# Linux ( Arch)
sudo pacman -S flutter dart

# Или через snap
sudo snap install flutter --classic

# Или через nix
nix develop
```

### Запуск

```bash
cd uniflow

# Установка зависимостей
flutter pub get

# Запуск на разных платформах
flutter run -d android
flutter run -d ios
flutter run -d windows
flutter run -d linux
flutter run -d chrome
```

### Сборка

```bash
# Android APK
flutter build apk

# iOS
flutter build ios

# Windows
flutter build windows

# Linux
flutter build linux
```

---

## Следующие шаги

### v1.1
- [ ] Уведомления о изменениях расписания
- [ ] Календарь семестра
- [ ] Экспорт в .ics
- [ ] Widget для дома (iOS/Android)

### v1.2
- [ ] Тёмная тема с переключением
- [ ] Поиск по всем параметрам
- [ ] История поиска
- [ ] Статистика посещений

---

## Файлы проекта

| Файл | Описание |
|------|----------|
| `lib/main.dart` | Точка входа |
| `lib/app.dart` | Конфигурация приложения |
| `lib/core/api/tulsu_api.dart` | API клиент |
| `lib/core/models/schedule.dart` | Модели данных |
| `lib/core/services/storage_service.dart` | Локальное хранилище |
| `lib/core/services/schedule_service.dart` | Сервис расписания |
| `lib/core/theme/app_theme.dart` | MD3 тема |
| `lib/features/schedule/screens/schedule_screen.dart` | Экран расписания |
| `lib/features/favorites/screens/favorites_screen.dart` | Экран избранного |
| `flake.nix` | Nix flake для сборки |
| `pubspec.yaml` | Зависимости |

---

## Вывод

✅ **Проект готов к разработке**

- Полная архитектура приложения
- Рабочий API клиент
- UI компоненты с MD3
- Состояние приложения (Riverpod)
- Локальное кэширование
- Поддержка всех платформ (iOS, Android, Windows, Linux)
- NixOS/Arch сборка

**Для запуска:** `cd uniflow && flutter pub get && flutter run`
