import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniflow/core/services/notification_service.dart';
import 'package:uniflow/core/services/storage_service.dart';
import 'package:uniflow/core/theme/theme_provider.dart';
import 'package:uniflow/features/schedule/screens/schedule_screen.dart';
import 'package:uniflow/features/notes/screens/notes_screen.dart';
import 'package:uniflow/features/performance/screens/performance_screen.dart';
import 'package:uniflow/features/profile/screens/profile_screen.dart';
import 'package:uniflow/features/profile/screens/onboarding_screen.dart';

/// Current tab index
final currentTabProvider = StateProvider<int>((ref) => 0);

/// Main app widget
class UniFlowApp extends ConsumerWidget {
  final bool startScreen;

  const UniFlowApp({super.key, this.startScreen = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final lightTheme = ref.watch(themeDataProvider);
    final darkTheme = ref.watch(themeDataProviderDark);

    return MaterialApp(
      title: 'UniFlow',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: settings.parsedThemeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ru'),
      home: startScreen ? const MainShell() : const OnboardingScreen(),
    );
  }
}

/// Shell with a solid, edge-to-edge bottom navigation bar (Gmail-style).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  static const _screens = <Widget>[
    ScheduleScreen(),
    NotesScreen(),
    PerformanceScreen(),
    ProfileScreen(),
  ];

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    // Ask for the notification permission once the first frame is up.
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupNotifications());
  }

  Future<void> _setupNotifications() async {
    if (!mounted) return;
    final service = ref.read(notificationServiceProvider);
    final storage = ref.read(storageServiceProvider);
    await service.init();
    final granted = await service.requestPermission();
    // One-time confirmation so the user sees that notifications work.
    if (granted && mounted && !storage.isNotificationsAsked()) {
      await storage.setNotificationsAsked();
      await service.show(
        1,
        'Уведомления включены',
        'UniFlow сообщит об изменениях расписания и оценок',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: MainShell._screens,
      ),
      // Solid bar, no floating rounded container: full-width surface color
      // with a tonal indicator pill, like Gmail's bottom navigation.
      // One tinted block holds the bar and the system gesture inset below
      // it, so the color is continuous to the screen edge: no white strip
      // above the bar and no floating gap under it (iOS home indicator).
      bottomNavigationBar: Builder(
        builder: (context) {
          final inset = MediaQuery.of(context).viewPadding.bottom;
          return Container(
            color: colorScheme.surfaceContainerLow,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NavigationBar(
                  selectedIndex: currentTab,
                  onDestinationSelected: (index) {
                    HapticFeedback.lightImpact();
                    ref.read(currentTabProvider.notifier).state = index;
                  },
                  animationDuration: const Duration(milliseconds: 400),
                  backgroundColor: colorScheme.surfaceContainerLow,
                  elevation: 0,
                  indicatorColor: colorScheme.primaryContainer,
                  height: 56,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    );
                  }),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.calendar_today_outlined),
                      selectedIcon: Icon(Icons.calendar_today),
                      label: 'Расписание',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.note_alt_outlined),
                      selectedIcon: Icon(Icons.note_alt),
                      label: 'Заметки',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.assessment_outlined),
                      selectedIcon: Icon(Icons.assessment),
                      label: 'Оценки',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Профиль',
                    ),
                  ],
                ),
                // Tinted strip under the bar: matches the bar color so the
                // home-indicator area never falls back to the window color.
                SizedBox(height: inset),
              ],
            ),
          );
        },
      ),
    );
  }
}
