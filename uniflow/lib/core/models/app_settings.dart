import 'package:flutter/material.dart';

/// Available accent color palette
class ColorOption {
  final String name;
  final int colorValue;

  const ColorOption({required this.name, required this.colorValue});
  Color get color => Color(colorValue);
}

const List<ColorOption> paletteOptions = [
  ColorOption(name: 'Фиолетовый', colorValue: 0xFF6750A4),
  ColorOption(name: 'Синий', colorValue: 0xFF0061A4),
  ColorOption(name: 'Зелёный', colorValue: 0xFF006D3C),
  ColorOption(name: 'Красный', colorValue: 0xFFBA1A1A),
  ColorOption(name: 'Оранжевый', colorValue: 0xFF9C4100),
  ColorOption(name: 'Бирюзовый', colorValue: 0xFF006A60),
  ColorOption(name: 'Жёлто-коричневый', colorValue: 0xFF7C5800),
  ColorOption(name: 'Розовый', colorValue: 0xFF984061),
];

/// Application settings model
class AppSettings {
  final int seedColorValue;
  final String themeMode; // 'system', 'light', 'dark'
  final bool showGroupsInSchedule;

  /// Demo mode: a throwaway generated schedule plus fun previews
  /// (live lesson countdown, sample change journal).
  final bool demoMode;

  const AppSettings({
    this.seedColorValue = 0xFF6750A4,
    this.themeMode = 'system',
    this.showGroupsInSchedule = true,
    this.demoMode = false,
  });

  Color get seedColor => Color(seedColorValue);

  ThemeMode get parsedThemeMode {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  AppSettings copyWith({
    int? seedColorValue,
    String? themeMode,
    bool? showGroupsInSchedule,
    bool? demoMode,
  }) {
    return AppSettings(
      seedColorValue: seedColorValue ?? this.seedColorValue,
      themeMode: themeMode ?? this.themeMode,
      showGroupsInSchedule: showGroupsInSchedule ?? this.showGroupsInSchedule,
      demoMode: demoMode ?? this.demoMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'seedColorValue': seedColorValue,
        'themeMode': themeMode,
        'showGroupsInSchedule': showGroupsInSchedule,
        'demoMode': demoMode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      seedColorValue: json['seedColorValue'] as int? ?? 0xFF6750A4,
      themeMode: json['themeMode'] as String? ?? 'system',
      showGroupsInSchedule: json['showGroupsInSchedule'] as bool? ?? true,
      demoMode: json['demoMode'] as bool? ?? false,
    );
  }
}
