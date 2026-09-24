import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniflow/core/theme/theme_provider.dart';

/// Demo mode (derived from app settings): switches the schedule to a
/// generated throwaway timetable and enables the fun preview features.
/// Defined here so [clockProvider] consumers and the schedule provider
/// share one source of truth.
final demoModeProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider.select((s) => s.demoMode));
});

/// App-wide ticking clock for "ongoing lesson" UI. Rebuilds subscribers
/// every 30 seconds so countdowns stay accurate without per-widget timers.
/// Demo mode keeps real time: the generated demo schedule always contains
/// a lesson that is running right now, so the countdown works live.
final clockProvider = StateNotifierProvider<ClockNotifier, DateTime>((ref) {
  final notifier = ClockNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});

class ClockNotifier extends StateNotifier<DateTime> {
  Timer? _timer;

  ClockNotifier() : super(DateTime.now()) {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      state = DateTime.now();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
