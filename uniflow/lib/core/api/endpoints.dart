/// API endpoints for TULSU Schedule
class TulsuEndpoints {
  TulsuEndpoints._();

  static const String baseUrl = 'https://tulsu.ru/schedule/queries';

  /// Search suggestions (autocomplete)
  static const String dictionaries = '/GetDictionaries.php';

  /// Get date range for schedule
  static const String dates = '/GetDates.php';

  /// Get time slots (pairs)
  static const String timeGroups = '/GetTimeGroups.php';

  /// Get schedule data
  static const String schedule = '/GetSchedule.php';

  /// Get academic calendar
  static const String calendar = '/GetCalendar.php';
}

/// API endpoints for TULSU Progress (academic performance)
class TulsuProgressEndpoints {
  TulsuProgressEndpoints._();

  static const String baseUrl = 'https://tulsu.ru/progress/queries';

  /// Get marks/grades
  /// GET /GetMarks.php?PERSONALAFFAIR={id}&GROUP_TITLE={group}
  static const String marks = '/GetMarks.php';
}

/// Search field types
enum SearchFieldType {
  group('GROUP_P'),
  teacher('PREP'),
  auditorium('AUD');

  final String value;
  const SearchFieldType(this.value);
}
