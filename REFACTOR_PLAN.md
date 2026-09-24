# UniFlow MD3 Refactor Plan

## Структура навигации
- **Bottom NavigationBar** с 2 вкладками:
  1. 📅 Расписание (ScheduleScreen)
  2. 📝 Заметки (NotesScreen)

## Экран "Расписание"
- **Top App Bar** с названием текущей группы + иконка настроек
- Если группа не задана — пустой state с CTA "Выбрать группу"
- Если группа задана:
  - Свайп/секция "Моя группа: 221341" с chip
  - Список избранных групп (horizontal chips)
  - Текущее расписание (неделя)
  - FAB: поиск другой группы/преподавателя
- **Bottom Sheet** для поиска и выбора группы

## Экран "Заметки"
- Список предметов (Card-based)
- Каждый предмет: название, количество задач, прогресс
- FAB: добавить предмет (выбрать из расписания или вручную)
- Цветовые коды для типов (лекция/практика/лабораторная)

## Экран "Предмет" (drill-down)
- Заголовок: название предмета + тип
- Секция "Задачи на сдачу" (TaskItem с чекбоксом)
- Секция "Заметки" (NoteItem - текст)
- FAB: добавить задачу/заметку

## Модели данных
- MyGroup: { groupNumber: String }
- FavoriteGroup: { groupNumber: String, addedAt: DateTime }
- Subject: { id, name, type, color, createdAt }
- Task: { id, subjectId, title, isCompleted, dueDate }
- Note: { id, subjectId, content, createdAt }

## Файлы для изменения/создания
- lib/main.dart - инициализация
- lib/app.dart - Shell с bottom nav + routes
- lib/core/models/ - все модели
- lib/core/services/storage_service.dart - Hive storage
- lib/features/schedule/ - переработанный расписание
- lib/features/notes/ - новый модуль заметок
