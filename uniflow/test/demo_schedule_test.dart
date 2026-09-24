import 'package:flutter_test/flutter_test.dart';
import 'package:uniflow/core/demo/demo_schedule.dart';
import 'package:uniflow/core/models/change_record.dart';

void main() {
  final now = DateTime.now();

  test('demo schedule spans three weeks around today', () {
    final items = buildDemoSchedule(now);
    expect(items, isNotEmpty);

    final dates = items
        .map((i) {
          try {
            return i.parsedDate;
          } catch (_) {
            return null;
          }
        })
        .whereType<DateTime>()
        .toList();
    expect(dates, isNotEmpty);

    final min = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final max = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    expect(
      now.subtract(const Duration(days: 7)).isBefore(max),
      isTrue,
      reason: 'current week must be covered',
    );
    expect(
      now.add(const Duration(days: 7)).isAfter(min),
      isTrue,
      reason: 'current week must be covered',
    );
  });

  test('demo schedule always contains a lesson running right now', () {
    final items = buildDemoSchedule(now);
    expect(
      items.any((i) => i.isOngoingAt(now)),
      isTrue,
      reason: 'the countdown gimmick needs a live lesson',
    );
  });

  test('demo time ranges are parseable', () {
    final items = buildDemoSchedule(now);
    final unparseable = items.where((i) => i.startsAt == null).toList();
    expect(unparseable, isEmpty);
  });

  test('demo changes seed all three kinds with isDemo flag', () {
    final items = buildDemoSchedule(now);
    final changes = buildDemoChanges(now, items);

    expect(changes, isNotEmpty);
    expect(changes.every((r) => r.isDemo), isTrue);
    expect(changes.map((r) => r.kind), contains(ChangeKind.modified));
    expect(changes.map((r) => r.kind), contains(ChangeKind.added));
    expect(changes.map((r) => r.kind), contains(ChangeKind.removed));

    // Modified/added demo records must point at real rows so the
    // lesson detail sheet can match them by fingerprint.
    final addedOrModified =
        changes.where((r) => r.kind != ChangeKind.removed).toList();
    for (final record in addedOrModified) {
      expect(
        items.any((i) => i.fingerprintRow == record.fingerprintRow),
        isTrue,
        reason: 'demo record "${record.subject}" must match a schedule row',
      );
    }
  });

  test('demo mutation moves one lesson and reports a room change', () {
    final items = buildDemoSchedule(now);
    final mutation = mutateDemoLesson(items, now);

    expect(mutation.change.kind, ChangeKind.modified);
    expect(mutation.change.isDemo, isTrue);
    expect(mutation.items, hasLength(items.length));
    expect(mutation.change.fieldChanges.single.field, 'Аудитория');
    expect(
      mutation.change.fieldChanges.single.before,
      isNot(mutation.change.fieldChanges.single.after),
    );

    // Exactly one row differs from the original schedule.
    var differences = 0;
    for (var i = 0; i < items.length; i++) {
      if (items[i].classroom != mutation.items[i].classroom) differences++;
    }
    expect(differences, 1, reason: 'only one lesson is moved per refresh');
  });

  test('demo changes are JSON round-trippable', () {
    final items = buildDemoSchedule(now);
    for (final record in buildDemoChanges(now, items)) {
      final restored = ChangeRecord.fromJson(record.toJson());
      expect(restored.kind, record.kind);
      expect(restored.subject, record.subject);
      expect(restored.fieldChanges.length, record.fieldChanges.length);
      expect(restored.isDemo, isTrue);
      expect(restored.fingerprintRow, record.fingerprintRow);
    }
  });
}
