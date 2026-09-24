import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:uniflow/core/models/schedule.dart';
import 'package:uniflow/core/providers/clock_provider.dart';
import 'package:uniflow/core/theme/app_theme.dart';
import 'package:uniflow/features/schedule/providers/schedule_provider.dart';

/// Opens the MD3 lesson detail bottom sheet.
///
/// Shared by the main schedule screen and the read-only preview
/// (search results / favorites).
void showLessonDetailSheet(BuildContext context, ScheduleItem lesson) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => LessonDetailSheet(lesson: lesson),
  );
}

/// Lesson Detail Sheet — layout: type=ЛВ, time=ПВ, date=ПН
///
/// Drag handle comes from the global `bottomSheetTheme.showDragHandle`,
/// so it must not be drawn manually here.
class LessonDetailSheet extends ConsumerWidget {
  final ScheduleItem lesson;

  const LessonDetailSheet({super.key, required this.lesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lessonColor = AppTheme.getColor(lesson.cssClass);

    // Live clock: banner while the lesson is running.
    final now = ref.watch(clockProvider);
    final isOngoing = lesson.isOngoingAt(now);
    final minutesLeft = isOngoing ? lesson.minutesLeftAt(now) : 0;

    // Countdown for today's lesson that hasn't started yet.
    final startAt = lesson.startsAt;
    final isUpcomingToday = !isOngoing &&
        startAt != null &&
        startAt.isAfter(now) &&
        startAt.year == now.year &&
        startAt.month == now.month &&
        startAt.day == now.day;
    final minutesUntilStart =
        isUpcomingToday ? lesson.minutesUntilStartAt(now) : 0;

    // Latest journal entry describing exactly this lesson.
    final changeRecord = ref.watch(scheduleScreenProvider
        .select((s) => s.latestChangeFor(lesson.fingerprintRow)));
    final changeNote = changeRecord?.summaryNote;

    // Date parts (DD.MM.YYYY)
    DateTime? parsedDate;
    try {
      parsedDate = lesson.parsedDate;
    } catch (_) {
      parsedDate = null;
    }
    final dateStr = parsedDate != null
        ? DateFormat('d MMMM', 'ru').format(parsedDate)
        : lesson.date;
    final weekdayStr =
        parsedDate != null ? DateFormat.EEEE('ru').format(parsedDate) : '';

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Section 1: Date + weekday ──
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const Gap(10),
              Text(
                dateStr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (weekdayStr.isNotEmpty) ...[
                const Gap(8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    weekdayStr,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Gap(14),

          // ── Section 2: Time + corpus ──
          Row(
            children: [
              // Time
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: lessonColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 15, color: lessonColor),
                    const Gap(6),
                    Text(
                      lesson.time,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: lessonColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // Corpus / classroom
              if (lesson.classroom.isNotEmpty) ...[
                const Gap(8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const Gap(6),
                      Text(
                        lesson.classroom,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          if (changeNote != null) ...[
            const Gap(14),
            _ChangeBanner(note: changeNote),
          ],

          if (isOngoing) ...[
            const Gap(14),
            _OngoingBanner(minutesLeft: minutesLeft),
          ],

          if (isUpcomingToday) ...[
            const Gap(14),
            _UpcomingBanner(minutesUntilStart: minutesUntilStart),
          ],

          const Gap(16),
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          const Gap(16),

          // ── Section 3: The rest ──
          // Subject
          Text(
            lesson.subject,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(14),

          // Type
          Row(
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 18, color: colorScheme.onSurfaceVariant),
              const Gap(10),
              Expanded(
                child: Text(
                  lesson.type.isEmpty
                      ? lesson.lessonType.displayName
                      : lesson.type,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          // Teacher
          if (lesson.teacher.isNotEmpty) ...[
            const Gap(10),
            _DetailRow(
              icon: Icons.person_outline,
              text: lesson.teacher,
              colorScheme: colorScheme,
              theme: theme,
            ),
          ],

          // Groups
          if (lesson.groups.isNotEmpty) ...[
            const Gap(18),
            Text(
              'Группы',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: lesson.groups.map((group) {
                return Chip(
                  label: Text(group.displayName,
                      style: theme.textTheme.labelSmall),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
          const Gap(8),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _DetailRow({
    required this.icon,
    required this.text,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const Gap(6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-width banner shown while the lesson is running: highlights the
/// card and shows how much time is left until it ends.
class _OngoingBanner extends StatelessWidget {
  final int minutesLeft;

  const _OngoingBanner({required this.minutesLeft});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.timelapse,
              size: 20, color: colorScheme.onPrimaryContainer),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Идёт сейчас',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(2),
                Text(
                  'До конца пары $minutesLeft мин',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.access_time,
              size: 18, color: colorScheme.onPrimaryContainer),
        ],
      ),
    );
  }
}

/// Banner shown before today's lesson starts: quiet secondary tonal
/// card with a countdown to the start time.
class _UpcomingBanner extends StatelessWidget {
  final int minutesUntilStart;

  const _UpcomingBanner({required this.minutesUntilStart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.watch_later_outlined,
              size: 20, color: colorScheme.onSecondaryContainer),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Начнётся скоро',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(2),
                Text(
                  'До начала пары '
                  '${formatDurationShort(minutesUntilStart)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.access_time,
              size: 18, color: colorScheme.onSecondaryContainer),
        ],
      ),
    );
  }
}

/// Banner shown when the lesson was affected by the latest schedule change.
class _ChangeBanner extends StatelessWidget {
  final String note;

  const _ChangeBanner({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final text = note == 'Новое занятие'
        ? 'Новое занятие в расписании'
        : 'Изменение расписания: $note';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.sync_alt, size: 16, color: colorScheme.onErrorContainer),
          const Gap(10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
