import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:uniflow/app.dart';
import 'package:uniflow/core/models/schedule.dart';
import 'package:uniflow/core/services/schedule_service.dart';
import 'package:uniflow/features/schedule/providers/schedule_provider.dart';
import 'package:uniflow/features/schedule/screens/schedule_changes_screen.dart';
import 'package:uniflow/features/schedule/screens/schedule_preview_screen.dart';
import 'package:uniflow/features/schedule/widgets/day_schedule.dart';
import 'package:uniflow/features/schedule/widgets/lesson_detail_sheet.dart';
import 'package:uniflow/shared/widgets/loading_indicator.dart';

/// Main Schedule Screen
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  final _scrollController = ScrollController();
  final _listKey = GlobalKey();
  final Map<String, GlobalKey> _dayKeys = {};
  bool _scrolledToToday = false;

  GlobalKey _getKeyForDay(DateTime day) {
    final key = '${day.year}-${day.month}-${day.day}';
    return _dayKeys.putIfAbsent(key, () => GlobalKey());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll so the given day header sits at the top of the list.
  /// Retries across frames because the list may still be loading
  /// (day keys are absent until the schedule items are built).
  /// Uses an instant jump: an animated scroll can be cancelled by a
  /// content re-layout (e.g. the week switching right after a pick).
  void _scrollToDay(DateTime day,
      {int attempt = 0, void Function(bool ok)? onDone}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _getKeyForDay(day).currentContext;
      if (ctx == null) {
        if (attempt < 12) {
          // addPostFrameCallback never schedules a frame on its own —
          // without this the retry chain stalls forever after a miss.
          WidgetsBinding.instance.scheduleFrame();
          _scrollToDay(day, attempt: attempt + 1, onDone: onDone);
        } else {
          onDone?.call(false);
        }
        return;
      }
      Scrollable.ensureVisible(
        ctx,
        duration: Duration.zero,
        curve: Curves.linear,
        alignment: 0.0,
      );
      onDone?.call(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleScreenProvider);

    // Auto-scroll when highlightedDate changes (calendar pick)
    ref.listen<ScheduleScreenState>(scheduleScreenProvider, (prev, next) {
      if (next.highlightedDate != null &&
          next.highlightedDate != prev?.highlightedDate) {
        _scrollToDay(next.highlightedDate!, onDone: (_) {});
      }
    });

    // On first open, jump straight to today's section of the week.
    if (!_scrolledToToday &&
        (state.currentGroup != null || state.isDemo) &&
        !state.schedule.isLoading &&
        state.schedule.error == null &&
        state.schedule.items.isNotEmpty &&
        state.isCurrentWeek) {
      _scrolledToToday = true;
      final now = DateTime.now();
      _scrollToDay(DateTime(now.year, now.month, now.day), onDone: (ok) {
        // The day card was not built yet — retry on a later qualifying
        // rebuild instead of giving up silently.
        if (!ok) _scrolledToToday = false;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Расписание'),
        centerTitle: false,
        actions: [
          // Change journal entry point — always visible (history
          // survives refreshes; badge only marks unseen changes).
          IconButton(
            icon: Badge(
              isLabelVisible: state.hasUnseenChanges,
              label: state.changeRecords.isNotEmpty
                  ? Text('${state.changeRecords.length}')
                  : null,
              child: const Icon(Icons.difference_outlined),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const ScheduleChangesScreen()),
            ),
            tooltip: 'Изменения',
          ),
          if (state.currentGroup != null || state.isDemo) ...[
            IconButton(
              icon: state.schedule.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: state.schedule.isLoading
                  ? null
                  : () async {
                      final msg = await ref
                          .read(scheduleScreenProvider.notifier)
                          .refresh();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(msg)),
                      );
                    },
              tooltip: 'Обновить',
            ),
          ],
          if (state.currentGroup != null) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showSearchSheet(context, ref),
              tooltip: 'Поиск',
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () => _openCalendar(context, ref),
              tooltip: 'Календарь',
            ),
          ],
          if (!state.isCurrentWeek)
            TextButton(
              onPressed: () =>
                  ref.read(scheduleScreenProvider.notifier).goToToday(),
              child: const Text('Сегодня'),
            ),
        ],
      ),
      body: state.currentGroup == null && !state.isDemo
          ? _buildNoGroupView(context, ref)
          : _buildScheduleView(context, ref, state),
    );
  }

  Widget _buildNoGroupView(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined,
                size: 80, color: colorScheme.primary.withValues(alpha: 0.3)),
            const Gap(24),
            Text('Выберите группу',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const Gap(8),
            Text(
              'Укажите номер группы\nв разделе «Профиль» → «Настройки»',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const Gap(32),
            FilledButton.icon(
              onPressed: () {
                ref.read(currentTabProvider.notifier).state = 3;
              },
              icon: const Icon(Icons.person),
              label: const Text('Открыть профиль'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleView(
    BuildContext context,
    WidgetRef ref,
    ScheduleScreenState state,
  ) {
    final schedule = state.schedule;

    // Stale-while-revalidate: when a local copy is already on screen,
    // keep it visible during a background sync and only show the slim
    // progress bar; the full-screen spinner is for a cold start with
    // nothing to display yet.
    final hasVisibleContent =
        schedule.error == null && schedule.items.isNotEmpty;

    return Column(
      children: [
        _GroupBadgeBar(state: state),
        _WeekNavigatorBar(
          state: state,
          onNextWeek: () =>
              ref.read(scheduleScreenProvider.notifier).goToNextWeek(),
          onPrevWeek: () =>
              ref.read(scheduleScreenProvider.notifier).goToPrevWeek(),
        ),
        if (schedule.isLoading && hasVisibleContent)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: schedule.isLoading && schedule.items.isEmpty
              ? const LoadingIndicator(message: 'Загрузка расписания...')
              : schedule.error != null
                  ? _buildError(
                      context, ref, schedule, Theme.of(context).colorScheme)
                  : schedule.items.isEmpty
                      ? _buildEmpty(Theme.of(context).colorScheme)
                      : _buildWeekSchedule(context, ref, state),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref,
      ScheduleState schedule, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 64, color: colorScheme.error.withValues(alpha: 0.5)),
          const Gap(16),
          Text('Ошибка загрузки', style: theme.textTheme.titleMedium),
          const Gap(8),
          Text(schedule.error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: colorScheme.onSurfaceVariant)),
          const Gap(16),
          FilledButton.tonal(
            onPressed: () =>
                ref.read(scheduleScreenProvider.notifier).refresh(),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy,
              size: 64, color: colorScheme.primary.withValues(alpha: 0.3)),
          const Gap(16),
          Text('Нет занятий на эту неделю',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildWeekSchedule(
      BuildContext context, WidgetRef ref, ScheduleScreenState state) {
    final weekByDay = state.currentWeekByDay;
    final allDays = List.generate(7, (i) {
      final day = state.currentWeekStart.add(Duration(days: i));
      return DateTime(day.year, day.month, day.day);
    });
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    return RefreshIndicator(
      onRefresh: () async {
        final msg = await ref.read(scheduleScreenProvider.notifier).refresh();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      },
      child: ListView(
        key: _listKey,
        controller: _scrollController,
        // Build every day of the week up front: a lazy SliverList leaves
        // far-off day cards unmounted, so GlobalKey lookups for scroll
        // targets (today / calendar picks) would silently find nothing.
        cacheExtent: 50000,
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          for (final day in allDays)
            Padding(
              key: _getKeyForDay(day),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: DaySchedule(
                date: day,
                lessons: weekByDay[day] ?? [],
                isToday: day == todayKey,
                isHighlighted: state.highlightedDate == day,
                onLessonClick: (lesson) => _showLessonDetail(context, lesson),
              ),
            ),
        ],
      ),
    );
  }

  void _showLessonDetail(BuildContext context, ScheduleItem lesson) {
    showLessonDetailSheet(context, lesson);
  }

  void _openCalendar(BuildContext context, WidgetRef ref) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020, 9, 1),
      lastDate: DateTime(2030, 8, 31),
      locale: const Locale('ru'),
    );
    if (picked != null && context.mounted) {
      ref.read(scheduleScreenProvider.notifier).selectDate(picked);
    }
  }

  void _showSearchSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _SearchBottomSheet(),
    );
  }
}

// ============================================================
// Group Badge Bar — "Моя группа" highlighted + favorites row
// ============================================================
class _GroupBadgeBar extends ConsumerWidget {
  final ScheduleScreenState state;

  const _GroupBadgeBar({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final notifier = ref.read(scheduleScreenProvider.notifier);
    final favorites = state.favoriteGroups;
    final currentGroup = state.currentGroup ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: "Моя группа" badge (highlighted, prominent);
          // in demo mode a «ДЕМО» chip replaces the (empty) group.
          if (state.isDemo)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.theaters_outlined,
                      size: 18, color: colorScheme.onTertiaryContainer),
                  const Gap(6),
                  Text(
                    'ДЕМО-режим',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else if (state.currentGroup != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school, size: 18, color: colorScheme.onPrimary),
                  const Gap(6),
                  Text(
                    currentGroup,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          // Row 2: Favorites chips (scrollable)
          if (favorites.isNotEmpty) ...[
            const Gap(6),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: favorites.length,
                separatorBuilder: (_, __) => const Gap(6),
                itemBuilder: (context, index) {
                  final fav = favorites[index];
                  return GestureDetector(
                    onLongPress: () {
                      _confirmRemoveFavorite(context, ref, fav.groupNumber);
                    },
                    child: ActionChip(
                      avatar: Icon(Icons.star,
                          size: 14, color: colorScheme.primary),
                      label: Text(fav.groupNumber,
                          style: theme.textTheme.labelMedium),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SchedulePreviewScreen(
                              searchValue: fav.groupNumber,
                              title: fav.groupNumber,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmRemoveFavorite(
      BuildContext context, WidgetRef ref, String groupNumber) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Удалить «$groupNumber» из избранного?'),
        action: SnackBarAction(
          label: 'Удалить',
          textColor: colorScheme.error,
          onPressed: () {
            ref
                .read(scheduleScreenProvider.notifier)
                .removeFavoriteGroup(groupNumber);
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

// ============================================================
// Week Navigator Bar
// ============================================================
class _WeekNavigatorBar extends StatelessWidget {
  final ScheduleScreenState state;
  final VoidCallback onNextWeek;
  final VoidCallback onPrevWeek;

  const _WeekNavigatorBar({
    required this.state,
    required this.onNextWeek,
    required this.onPrevWeek,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final weekInfo = state.weekInfo;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: state.isCurrentWeek
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevWeek,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Предыдущая неделя',
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Неделя ${weekInfo.weekNumber}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: state.isCurrentWeek
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${weekInfo.dateRangeShort} (${weekInfo.isEven ? 'чётная' : 'нечётная'})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNextWeek,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Следующая неделя',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Search Bottom Sheet — preview + favorite toggle
// ============================================================
class _SearchBottomSheet extends ConsumerStatefulWidget {
  const _SearchBottomSheet();

  @override
  ConsumerState<_SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends ConsumerState<_SearchBottomSheet> {
  final _controller = TextEditingController();
  List<SearchResult> _results = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    try {
      final service = ref.read(scheduleServiceProvider);
      final results = await service.search(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final notifier = ref.read(scheduleScreenProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Column(
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                child: Row(
                  children: [
                    Text('Поиск', style: theme.textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Группа, преподаватель или аудитория',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              _search('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _search,
                ),
              ),
              const Gap(8),
              // Results
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty
                        ? _buildEmptyState(context)
                        : Material(
                            child: ListView.builder(
                              controller: scrollController,
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final result = _results[index];
                                final isFav =
                                    notifier.isFavoriteGroup(result.value);
                                return ListTile(
                                  leading: Icon(_iconForType(result.type)),
                                  title: Text(result.value),
                                  subtitle: Text(result.type.displayName),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Favorite toggle
                                      IconButton(
                                        icon: Icon(
                                          isFav
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 20,
                                        ),
                                        color: isFav
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                        onPressed: () {
                                          if (isFav) {
                                            notifier.removeFavoriteGroup(
                                                result.value);
                                          } else {
                                            notifier
                                                .addFavoriteGroup(result.value);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    '«${result.value}» добавлена в избранное'),
                                                duration:
                                                    const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const Icon(Icons.chevron_right, size: 20),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => SchedulePreviewScreen(
                                          searchValue: result.value,
                                          title: result.value,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search,
              size: 48, color: colorScheme.primary.withValues(alpha: 0.3)),
          const Gap(8),
          Text('Введите минимум 2 символа',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  IconData _iconForType(SearchResultType type) {
    switch (type) {
      case SearchResultType.group:
        return Icons.group_outlined;
      case SearchResultType.teacher:
        return Icons.person_outline;
      case SearchResultType.auditorium:
        return Icons.room_outlined;
      case SearchResultType.subject:
        return Icons.book_outlined;
    }
  }
}
