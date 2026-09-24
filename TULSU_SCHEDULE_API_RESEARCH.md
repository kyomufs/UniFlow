# Исследование API расписания ТулГУ

## Вывод: API существует и полностью открыт для использования

Сайт расписания ТулГУ (`https://tulsu.ru/schedule/`) использует **открытый PHP API без авторизации**. Все данные доступны в формате JSON через GET-запросы.

---

## Доступные API endpoints

Базовый URL: `https://tulsu.ru/schedule/queries/`

### 1. Автодополнение (словарь)
```
GET /queries/GetDictionaries.php?term={поисковый_запрос}
```
**Ответ:** JSON-массив вариантов
```json
[
  {"value": "221341", "SORT": "1"},
  {"value": "221341и", "SORT": "1"},
  {"value": "221341р", "SORT": "1"},
  {"value": "221341:01", "SORT": "1"}
]
```
**Поддерживает поиск по:**
- Номеру группы (например, `221341`)
- ФИО преподавателя (например, `Иванов`)
- Номеру аудитории (например, `Гл.-408`)

---

### 2. Диапазон дат для расписания
```
GET /queries/GetDates.php?search_value={значение_поиска}
```
**Ответ:**
```json
{
  "MIN_DATE": "2026-08-31",
  "MAX_DATE": "2026-12-27",
  "SEARCH_FIELD": "GROUP_P"
}
```
- `SEARCH_FIELD` определяет тип поиска: `GROUP_P` (группа), `PREP` (преподаватель) или `AUD` (аудитория)
- Возвращает минимальную и максимальную даты расписания

---

### 3. Временные слоты (пары)
```
GET /queries/GetTimeGroups.php?search_field={тип}&search_value={значение}
```
**Ответ:** Массив временных слотов
```json
[
  {"TIME_START": "07:45", "TIME_END": "09:20"},
  {"TIME_START": "09:40", "TIME_END": "11:15"},
  {"TIME_START": "11:35", "TIME_END": "13:10"},
  {"TIME_START": "13:40", "TIME_END": "15:15"},
  {"TIME_START": "15:35", "TIME_END": "17:10"},
  {"TIME_START": "17:30", "TIME_END": "19:05"}
]
```

---

### 4. Расписание занятий (основной endpoint)
```
GET /queries/GetSchedule.php?search_field={тип}&search_value={значение}
```
**Ответ:** Массив объектов расписания
```json
[
  {
    "DATE_Z": "01.09.2026",           // Дата (ДД.ММ.ГГГГ)
    "TIME_Z": "11:35 - 13:10",        // Время пары
    "DISCIP": "Исследование операций и методы оптимизации", // Название предмета
    "KOW": "Лекции",                  // Форма занятия (Лекции/Лабораторные/Практические)
    "AUD": "Гл.-408",                 // Аудитория
    "PREP": "Двоенко Сергей Данилович", // Преподаватель
    "GROUPS": [                        // Массив групп
      {
        "GROUP_P": "221341",          // Номер группы
        "PRIM": ""                    // Примечание (подгруппа)
      }
    ],
    "CLASS": "lecture"                 // CSS-класс для стилизации: lecture/practice/lab
  }
]
```

**Значения `CLASS`:**
- `lecture` — лекция
- `practice` — практика
- `lab` — лабораторная

---

### 5. Учебный календарь
```
GET /queries/GetCalendar.php?search_value={значение}
```
**Ответ:**
```json
[
  {"BEGIN_DATE": "01.09.2026", "END_DATE": "22.12.2026", "VID": "теоретич. обуч."},
  {"BEGIN_DATE": "21.09.2026", "END_DATE": "18.10.2026", "VID": "ликвидация задолженности"},
  {"BEGIN_DATE": "18.10.2026", "END_DATE": "31.10.2026", "VID": "первый рубежный контроль"},
  {"BEGIN_DATE": "23.12.2026", "END_DATE": "25.01.2027", "VID": "экзамен. сессия"},
  {"BEGIN_DATE": "26.01.2027", "END_DATE": "08.02.2027", "VID": "каникулы"}
]
```

---

## Алгоритм получения расписания

### Шаг 1: Поиск (если нужен autocomplete)
```javascript
const response = await fetch('https://tulsu.ru/schedule/queries/GetDictionaries.php?term=221341');
const suggestions = await response.json();
// suggestions = [{value: "221341", SORT: "1"}, ...]
```

### Шаг 2: Получение диапазона дат
```javascript
const response = await fetch('https://tulsu.ru/schedule/queries/GetDates.php?search_value=221341');
const dates = await response.json();
// dates = {MIN_DATE: "2026-08-31", MAX_DATE: "2026-12-27", SEARCH_FIELD: "GROUP_P"}
```

### Шаг 3: Получение расписания
```javascript
const response = await fetch(`https://tulsu.ru/schedule/queries/GetSchedule.php?search_field=${dates.SEARCH_FIELD}&search_value=221341`);
const schedule = await response.json();
// schedule = [{DATE_Z: "01.09.2026", TIME_Z: "11:35 - 13:10", DISCIP: "...", ...}, ...]
```

### Шаг 4 (опционально): Учебный календарь
```javascript
const response = await fetch('https://tulsu.ru/schedule/queries/GetCalendar.php?search_value=221341');
const calendar = await response.json();
// calendar = [{BEGIN_DATE: "01.09.2026", END_DATE: "22.12.2026", VID: "теоретич. обуч."}, ...]
```

---

## Пример полного кода (JavaScript)

```javascript
const BASE_URL = 'https://tulsu.ru/schedule/queries';

async function getSchedule(searchValue) {
  // Шаг 1: Получаем диапазон дат и тип поиска
  const datesResponse = await fetch(`${BASE_URL}/GetDates.php?search_value=${encodeURIComponent(searchValue)}`);
  const datesData = await datesResponse.json();

  if (!datesData.MIN_DATE) {
    throw new Error('Расписание не найдено');
  }

  // Шаг 2: Получаем расписание
  const scheduleResponse = await fetch(
    `${BASE_URL}/GetSchedule.php?search_field=${datesData.SEARCH_FIELD}&search_value=${encodeURIComponent(searchValue)}`
  );
  const schedule = await scheduleResponse.json();

  // Шаг 3: Получаем учебный календарь
  const calendarResponse = await fetch(`${BASE_URL}/GetCalendar.php?search_value=${encodeURIComponent(searchValue)}`);
  const calendar = await calendarResponse.json();

  return {
    dateRange: {
      min: datesData.MIN_DATE,
      max: datesData.MAX_DATE,
      searchField: datesData.SEARCH_FIELD
    },
    schedule,
    calendar
  };
}

// Использование
getSchedule('221341').then(data => {
  console.log('Диапазон дат:', data.dateRange);
  console.log('Количество пар:', data.schedule.length);
  console.log('Расписание:', data.calendar);
});
```

---

## Примеры поиска

| Запрос | Тип | Результат |
|--------|-----|-----------|
| `221341` | Группа | Расписание группы 221341 |
| `221341:01` | Подгруппа | Расписание подгруппы 01 |
| `Двоенко` | Преподаватель | Расписание преподавателя |
| `Гл.-408` | Аудитория | Расписание аудитории |

---

## Ограничения и особенности

1. **Нет авторизации** — API полностью открыт
2. **Нет rate limiting** — но стоит добавить кэширование (расписание меняется редко)
3. **Даты в формате DD.MM.YYYY** — нужен парсинг
4. **Время пар фиксировано** — 6 пар в день (с 07:45 до 19:05)
5. **Расписание на семестр** — данные загружаются один раз и обновляются при изменениях

---

## Рекомендации для мобильного приложения

1. **Кэширование:** Сохраняйте расписание локально, обновляйте раз в день
2. **Оффлайн-доступ:** Показывайте кэшированное расписание без интернета
3. **Push-уведомления:** Проверяйте изменения расписания (сравнивайте с кэшем)
4. **Поиск:** Используйте `GetDictionaries.php` для autocomplete
5. **Неделя:** Группируйте пары по дням недели для удобного просмотра

---

## Структура данных для приложения

```typescript
interface ScheduleItem {
  date: string;           // "01.09.2026"
  time: string;           // "11:35 - 13:10"
  subject: string;        // "Исследование операций"
  type: 'lecture' | 'practice' | 'lab';
  classroom: string;      // "Гл.-408"
  teacher: string;        // "Двоенко Сергей Данилович"
  groups: Array<{
    number: string;       // "221341"
    subgroup: string;     // "" или "01"
  }>;
}

interface DateRange {
  min: string;
  max: string;
  searchField: 'GROUP_P' | 'PREP' | 'AUD';
}

interface CalendarItem {
  beginDate: string;
  endDate: string;
  type: string;           // "теоретич. обуч." | "каникулы" | ...
}
```

---

## Заключение

API расписания ТулГУ — это **идеальный кейс для создания приложения**:
- ✅ Открытый API без авторизации
- ✅ Структурированные JSON-данные
- ✅ Поддержка поиска по группам, преподавателям, аудиториям
- ✅ Данные актуализируются на сервере
- ✅ Минимальная нагрузка на сервер (3-4 запроса на загрузку)

**Единственная проблема:** Нет CORS-заголовков (нужен backend-прокси или использование в WebView/React Native).
