// One-off generator for the UniFlow launcher icons (iOS + Android).
// Renders a vector design (no fonts, no external assets) with dart:ui and
// writes every required PNG size. Run locally:
//   nix develop -c flutter test test/icon_generator_test.dart
// The file is intentionally NOT part of the regular test suite in CI
// (guarded by the env var) and can be deleted after regenerating icons.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Design canvas side (all coordinates below are in this space).
const double kCanvas = 1024;

/// Brand gradient endpoints (seed color -> indigo, matches launcher bg).
const Color kGradStart = Color(0xFF6750A4);
const Color kGradEnd = Color(0xFF3B46CD);

/// Paints the full icon: diagonal gradient background + schedule glyph.
void paintIcon(Canvas canvas, {required bool withBackground}) {
  if (withBackground) {
    canvas.drawRect(
      Offset.zero & const Size(kCanvas, kCanvas),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kGradStart, kGradEnd],
        ).createShader(Offset.zero & const Size(kCanvas, kCanvas)),
    );
    // Soft radial highlight in the top-left corner for depth.
    canvas.drawRect(
      Offset.zero & const Size(kCanvas, kCanvas),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.55, -0.65),
          radius: 0.9,
          colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
        ).createShader(Offset.zero & const Size(kCanvas, kCanvas)),
    );
  }

  // "Timetable" glyph: three left-aligned stadium rows of decreasing
  // width (centered block), the last one dimmed — a schedule at a glance.
  const rows = <(double, double, double)>[
    (232, 300, 0.95), // x, y, opacity (width fixed per row below)
    (232, 464, 0.95),
    (232, 628, 0.50),
  ];
  const widths = <double>[560, 560, 340];
  for (var i = 0; i < rows.length; i++) {
    final (x, y, opacity) = rows[i];
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, widths[i], 96),
      const Radius.circular(48),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
  }

  // Accent dot on the first row's right end (a highlighted lesson).
  canvas.drawCircle(
    const Offset(744, 348),
    32,
    Paint()..color = const Color(0xFFFFD6E7),
  );
}

Future<void> writePng(double size, String path) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(size / kCanvas);
  paintIcon(canvas, withBackground: true);
  final image = await recorder.endRecording().toImage(
        size.round(),
        size.round(),
      );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
  stdout.writeln('  wrote $path (${size.round()}x${size.round()})');
}

Future<void> writeForeground(double size, String path) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(size / kCanvas);
  paintIcon(canvas, withBackground: false);
  final image = await recorder.endRecording().toImage(
        size.round(),
        size.round(),
      );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
  stdout.writeln('  wrote $path (foreground ${size.round()}px)');
}

void main() {
  test('generate launcher icons', () async {
    if (Platform.environment['UNIFLOW_GEN_ICONS'] != '1') {
      // Not a real test run: just skip silently (guarded one-off tool).
      return;
    }

    const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    const iosIcons = <String, double>{
      'Icon-App-20x20@1x.png': 20,
      'Icon-App-20x20@2x.png': 40,
      'Icon-App-20x20@3x.png': 60,
      'Icon-App-29x29@1x.png': 29,
      'Icon-App-29x29@2x.png': 58,
      'Icon-App-29x29@3x.png': 87,
      'Icon-App-40x40@1x.png': 40,
      'Icon-App-40x40@2x.png': 80,
      'Icon-App-40x40@3x.png': 120,
      'Icon-App-60x60@2x.png': 120,
      'Icon-App-60x60@3x.png': 180,
      'Icon-App-76x76@1x.png': 76,
      'Icon-App-76x76@2x.png': 152,
      'Icon-App-83.5x83.5@2x.png': 167,
      'Icon-App-1024x1024@1x.png': 1024,
    };
    stdout.writeln('iOS icons:');
    for (final e in iosIcons.entries) {
      await writePng(e.value, '$ios/${e.key}');
    }

    const androidDensities = <String, double>{
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    const res = 'android/app/src/main/res';
    stdout.writeln('Android icons:');
    for (final e in androidDensities.entries) {
      final dir = '$res/mipmap-${e.key}';
      await writePng(e.value, '$dir/ic_launcher.png');
      await writePng(e.value, '$dir/ic_launcher_round.png');
    }
    // Adaptive icon foreground (108dp canvas, glyph fits the safe zone).
    await writeForeground(432, '$res/drawable/ic_launcher_foreground.png');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
