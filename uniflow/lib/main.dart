import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:uniflow/app.dart';
import 'package:uniflow/core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw edge-to-edge so the UI extends behind the gesture pill instead
  // of leaving a system inset strip below the navigation bar.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  // Initialize locale data for intl (Russian date formatting)
  await initializeDateFormatting('ru');

  // Initialize storage
  final storageService = StorageService();
  await storageService.init();

  // Clear old cache
  await storageService.clearOldCache();

  final onboardingDone = storageService.isOnboardingCompleted();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: UniFlowApp(startScreen: onboardingDone),
    ),
  );
}
