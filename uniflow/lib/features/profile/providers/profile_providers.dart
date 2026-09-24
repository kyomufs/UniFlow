import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incremented whenever profile data (group, subgroup, student ID) changes.
/// Providers that cache profile-derived state watch this to rebuild/reload.
final profileRevisionProvider = StateProvider<int>((ref) => 0);
