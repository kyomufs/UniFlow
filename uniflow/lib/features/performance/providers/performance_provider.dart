import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniflow/core/api/tulsu_api.dart';
import 'package:uniflow/core/demo/demo_marks.dart';
import 'package:uniflow/core/providers/clock_provider.dart';
import 'package:uniflow/core/utils/error_messages.dart';
import 'package:uniflow/core/services/connectivity_service.dart';
import 'package:uniflow/core/services/storage_service.dart';
import 'package:uniflow/features/profile/providers/profile_providers.dart';

/// Performance screen state
class PerformanceState {
  final List<MarksItem> marks;
  final bool isLoading;
  final String? error;
  final int selectedSemester;

  const PerformanceState({
    this.marks = const [],
    this.isLoading = false,
    this.error,
    this.selectedSemester = 0, // 0 = latest
  });

  /// Available semesters (sorted ascending: 1, 2, 3...)
  List<int> get availableSemesters {
    final terms = marks.map((m) => m.termNumber).toSet().toList();
    terms.sort((a, b) => a.compareTo(b));
    return terms;
  }

  /// Marks for the selected semester
  List<MarksItem> get semesterMarks {
    if (selectedSemester == 0 && marks.isNotEmpty) {
      final terms = availableSemesters;
      if (terms.isNotEmpty) {
        return marks.where((m) => m.termNumber == terms.first).toList();
      }
      return marks;
    }
    return marks.where((m) => m.termNumber == selectedSemester).toList();
  }

  /// Stats for selected semester
  int get totalSubjects => semesterMarks.length;
  int get attestedCount => semesterMarks.where((m) => m.isAttested).length;
  int get notAttestedCount => totalSubjects - attestedCount;

  /// The latest (highest) semester number
  int get latestSemester =>
      availableSemesters.isEmpty ? 0 : availableSemesters.last;

  PerformanceState copyWith({
    List<MarksItem>? marks,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? selectedSemester,
  }) {
    return PerformanceState(
      marks: marks ?? this.marks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedSemester: selectedSemester ?? this.selectedSemester,
    );
  }
}

class PerformanceNotifier extends StateNotifier<PerformanceState> {
  final ProgressApiClient _api;
  final StorageService _storage;
  final ConnectivityService _connectivity;
  final bool _demo;

  PerformanceNotifier(this._api, this._storage, this._connectivity,
      {bool demo = false})
      : _demo = demo,
        super(const PerformanceState()) {
    loadMarks();
  }

  /// Loads marks and returns a user-facing message for manual refreshes.
  /// Never gated by connectivity: hits the API first, falls back to the
  /// Hive cache, and reports "no internet" explicitly on failure.
  /// Demo mode short-circuits: serves generated marks, no API, no cache.
  Future<String> loadMarks() async {
    if (_demo) {
      state = state.copyWith(marks: buildDemoMarks(), clearError: true);
      _autoSelectSemester();
      return 'Демо-оценки обновлены';
    }

    final studentId = _storage.getStudentId();
    final group = _storage.getFullAcademicGroup();

    if (studentId == null || group == null) {
      final msg = studentId == null
          ? 'Укажите номер зачётки в профиле'
          : 'Укажите подгруппу в профиле (например, 01)';
      state = state.copyWith(
        error: msg,
      );
      return msg;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    // Stale-while-revalidate: paint the local snapshot first (this runs
    // synchronously during construction, before any network wait), then
    // sync with the API and swap the data in place. Slow internet keeps
    // the existing marks on screen instead of blanking them.
    final cached = _storage.getCachedMarks(studentId: studentId, group: group);
    if (state.marks.isEmpty && cached != null && cached.isNotEmpty) {
      state = state.copyWith(marks: cached, clearError: true);
      _autoSelectSemester();
    }

    // No connectivity gate: a stale cached "offline" verdict must never
    // block a refresh — hit the API directly, then fall back to the cache.
    try {
      final marks = await _api.getMarks(
        personalAffair: studentId,
        groupTitle: group,
      );
      if (!mounted) return 'Не удалось обновить оценки';
      await _storage.cacheMarks(
          studentId: studentId, group: group, marks: marks);
      state = state.copyWith(marks: marks, isLoading: false);
      _autoSelectSemester();
      return 'Оценки обновлены';
    } catch (e) {
      // Offline or API failure: keep serving the snapshot instead of
      // wiping the screen, so marks survive network drops.
      if (!mounted) return 'Не удалось обновить оценки';
      final servedCache = cached != null && cached.isNotEmpty;
      final msg = await _failureMessage(e, servedCache: servedCache);
      if (servedCache) {
        state =
            state.copyWith(marks: cached, isLoading: false, clearError: true);
        _autoSelectSemester();
        return msg;
      }
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  /// Explicit failure message: re-probe connectivity (bypassing the 30s
  /// probe cache) so "no internet" is stated exactly, not guessed.
  Future<String> _failureMessage(Object e, {required bool servedCache}) async {
    _connectivity.invalidateCache();
    final online = await _connectivity.checkConnectivity();
    final base =
        online ? ErrorMessages.fromException(e) : 'Нет подключения к интернету';
    return servedCache ? '$base — показаны сохранённые оценки' : base;
  }

  void _autoSelectSemester() {
    if (state.availableSemesters.isNotEmpty) {
      state = state.copyWith(selectedSemester: state.availableSemesters.first);
    }
  }

  void selectSemester(int semester) {
    state = state.copyWith(selectedSemester: semester);
  }
}

/// Whether performance is configured (student ID + group)
final isPerformanceConfiguredProvider = Provider<bool>((ref) {
  // Demo mode never needs real profile fields — marks are generated.
  if (ref.watch(demoModeProvider)) return true;
  // Re-evaluate when profile fields change (group/subgroup/student ID).
  ref.watch(profileRevisionProvider);
  final storage = ref.watch(storageServiceProvider);
  return storage.getStudentId() != null &&
      storage.getFullAcademicGroup() != null;
});

final performanceProvider =
    StateNotifierProvider<PerformanceNotifier, PerformanceState>((ref) {
  // Recreate the notifier (and reload marks) whenever profile data changes.
  ref.watch(profileRevisionProvider);
  final demo = ref.watch(demoModeProvider);
  return PerformanceNotifier(
    ref.watch(progressApiClientProvider),
    ref.watch(storageServiceProvider),
    ref.watch(connectivityServiceProvider),
    demo: demo,
  );
});
