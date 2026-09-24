import 'dart:math';

import 'package:uniflow/core/models/change_record.dart';
import 'package:uniflow/core/models/schedule.dart';

/// Funny Russian subjects for the generated demo timetable.
const demoSubjects = [
  'Математический анализ (навсегда)',
  'Дискретная математика',
  'История ГИТов',
  'Физкультура (да, снова)',
  'Базы данных',
  'Веб-разработка',
  'Теория вероятностей (ваш шанс)',
  'ООП и паттерны',
  'Компьютерные сети',
  'Английский для документации',
];

/// Fake teachers for demo mode.
const demoTeachers = [
  'Иванов И. И.',
  'Петров П. П.',
  'Сидорова А. А.',
  'Кузнецов Д. М.',
  'Волкова Е. В.',
];

/// Fake classrooms for demo mode.
const demoClassrooms = ['305', '407', 'Гл-211', '12-121', '1-108'];

const demoGroup = '24-Демо';

const _demoSlots = [
  '08:00 - 09:30',
  '09:45 - 11:15',
  '11:30 - 13:00',
  '13:45 - 15:15',
  '15:30 - 17:00',
];

const _demoTypes = [
  ('Лекции', 'lecture'),
  ('Практические занятия', 'practice'),
  ('Лабораторные работы', 'lab'),
];

/// Builds a throwaway demo timetable for the weeks around [now]
/// (Mon–Sat), and guarantees one lesson that is running at [now] so the
/// «До конца пары» countdown is always demonstrable.
List<ScheduleItem> buildDemoSchedule(DateTime now) {
  final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  final items = <ScheduleItem>[];

  for (final weekOffset in const [-1, 0, 1]) {
    final week = monday.add(Duration(days: 7 * weekOffset));
    for (var day = 0; day < 6; day++) {
      final date = week.add(Duration(days: day));
      final count = day == 5 ? 3 : (day.isEven ? 5 : 4);
      for (var i = 0; i < count; i++) {
        final seed = (weekOffset + 1) * 97 + day * 13 + i * 7;
        final (type, cssClass) = _demoTypes[seed % _demoTypes.length];
        items.add(ScheduleItem(
          date: _fmtDate(date),
          time: _demoSlots[i % _demoSlots.length],
          subject: demoSubjects[seed % demoSubjects.length],
          type: type,
          classroom: demoClassrooms[seed % demoClassrooms.length],
          teacher: demoTeachers[(seed + 2) % demoTeachers.length],
          groups: const [GroupInfo(number: demoGroup)],
          cssClass: cssClass,
        ));
      }
    }
  }

  return _withOngoingLesson(items, now);
}

/// Seeded demo change journal (room mod, time+teacher mod, added,
/// removed) so the «Изменения» screen has content right away.
List<ChangeRecord> buildDemoChanges(DateTime now, List<ScheduleItem> items) {
  final today = DateTime(now.year, now.month, now.day);
  final upcoming = items.where((i) {
    try {
      return !i.parsedDate.isBefore(today);
    } catch (_) {
      return false;
    }
  }).toList();
  final pool = upcoming.isNotEmpty ? upcoming : items;
  if (pool.isEmpty) return const [];

  final first = pool[0];
  final second = pool.length > 1 ? pool[1] : pool[0];
  final third = pool.length > 2 ? pool[2] : pool[0];

  return [
    // Room moved.
    ChangeRecord(
      detectedAt: now.subtract(const Duration(hours: 2)),
      kind: ChangeKind.modified,
      date: first.date,
      subject: first.subject,
      type: first.type,
      time: first.time,
      classroom: first.classroom,
      teacher: first.teacher,
      fieldChanges: [
        FieldChange(
          field: 'Аудитория',
          before: first.classroom == '1-108' ? '305' : '1-108',
          after: first.classroom,
        ),
      ],
      isDemo: true,
    ),
    // Time and teacher reshuffled.
    ChangeRecord(
      detectedAt: now.subtract(const Duration(hours: 6)),
      kind: ChangeKind.modified,
      date: second.date,
      subject: second.subject,
      type: second.type,
      time: second.time,
      classroom: second.classroom,
      teacher: second.teacher,
      fieldChanges: [
        const FieldChange(
          field: 'Время',
          before: '09:45 - 11:15',
          after: '11:30 - 13:00',
        ),
        FieldChange(
          field: 'Преподаватель',
          before: demoTeachers[
              (demoTeachers.indexOf(second.teacher) + 1) % demoTeachers.length],
          after: second.teacher,
        ),
      ],
      isDemo: true,
    ),
    // Brand-new lesson.
    ChangeRecord(
      detectedAt: now.subtract(const Duration(days: 1, hours: 3)),
      kind: ChangeKind.added,
      date: third.date,
      subject: third.subject,
      type: third.type,
      time: third.time,
      classroom: third.classroom,
      teacher: third.teacher,
      isDemo: true,
    ),
    // Cancelled lesson (old values, no counterpart in the schedule).
    ChangeRecord(
      detectedAt: now.subtract(const Duration(days: 1, hours: 7)),
      kind: ChangeKind.removed,
      date: _fmtDate(today.add(const Duration(days: 2))),
      subject: 'Физкультура (отменили, наконец-то)',
      type: 'Практические занятия',
      time: '17:15 - 18:45',
      classroom: 'Зал №2',
      teacher: 'Волкова Е. В.',
      isDemo: true,
    ),
  ];
}

/// Result of a demo refresh: the mutated timetable plus the change it
/// produced (shown in the journal and announced via notification).
class DemoMutation {
  final List<ScheduleItem> items;
  final ChangeRecord change;

  const DemoMutation({required this.items, required this.change});
}

/// Moves one random demo lesson to another room, mimicking a real
/// schedule change end-to-end.
DemoMutation mutateDemoLesson(List<ScheduleItem> items, DateTime now) {
  if (items.isEmpty) {
    final fresh = buildDemoSchedule(now);
    return DemoMutation(
      items: fresh,
      change: buildDemoChanges(now, fresh).first,
    );
  }

  final rng = Random(now.microsecondsSinceEpoch);
  final index = rng.nextInt(items.length);
  final old = items[index];
  final candidates =
      demoClassrooms.where((c) => c != old.classroom).toList(growable: false);
  final newRoom = candidates[rng.nextInt(candidates.length)];

  final mutated = ScheduleItem(
    date: old.date,
    time: old.time,
    subject: old.subject,
    type: old.type,
    classroom: newRoom,
    teacher: old.teacher,
    groups: old.groups,
    cssClass: old.cssClass,
  );

  return DemoMutation(
    items: [...items]..[index] = mutated,
    change: ChangeRecord(
      detectedAt: now,
      kind: ChangeKind.modified,
      date: old.date,
      subject: old.subject,
      type: old.type,
      time: old.time,
      classroom: newRoom,
      teacher: old.teacher,
      fieldChanges: [
        FieldChange(field: 'Аудитория', before: old.classroom, after: newRoom),
      ],
      isDemo: true,
    ),
  );
}

/// Drops the generated lessons of today that overlap the synthetic
/// "running now" slot and appends that slot itself.
List<ScheduleItem> _withOngoingLesson(List<ScheduleItem> items, DateTime now) {
  final startMin = max(0, ((now.hour * 60 + now.minute - 25) ~/ 5) * 5);
  final endMin = min(24 * 60 - 1, startMin + 85);
  final todayKey = _fmtDate(now);

  final filtered = items.where((i) {
    if (i.date != todayKey) return true;
    final range = _minutesOf(i.time);
    if (range == null) return true;
    final (itemStart, itemEnd) = range;
    final overlaps = itemStart < endMin && startMin < itemEnd;
    return !overlaps;
  }).toList();

  final seed = now.day;
  final (type, cssClass) = _demoTypes[seed % _demoTypes.length];
  filtered.add(ScheduleItem(
    date: todayKey,
    time: '${_fmtMin(startMin)} - ${_fmtMin(endMin)}',
    subject: 'Непредвиденная пара (вы её заказывали)',
    type: type,
    classroom: demoClassrooms[seed % demoClassrooms.length],
    teacher: demoTeachers[seed % demoTeachers.length],
    groups: const [GroupInfo(number: demoGroup)],
    cssClass: cssClass,
  ));

  return filtered;
}

/// "HH:MM - HH:MM" → (startMinute, endMinute); null when unparseable.
(int, int)? _minutesOf(String time) {
  final match =
      RegExp(r'(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})').firstMatch(time);
  if (match == null) return null;
  final start = int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  var end = int.parse(match.group(3)!) * 60 + int.parse(match.group(4)!);
  if (end <= start) end += 24 * 60;
  return (start, end);
}

String _fmtMin(int minute) {
  final h = (minute ~/ 60).toString().padLeft(2, '0');
  final m = (minute % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

String _fmtDate(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return '$day.$month.${d.year}';
}
