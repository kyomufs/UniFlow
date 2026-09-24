// Temporary sanity check for generated icons: samples a few pixels.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

Future<({int r, int g, int b})> pixel(String path, int x, int y) async {
  final bytes = File(path).readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final i = (y * frame.image.width + x) * 4;
  return (
    r: data!.getUint8(i),
    g: data.getUint8(i + 1),
    b: data.getUint8(i + 2),
  );
}

void main() {
  test('icon pixels', () async {
    const path =
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png';
    final topLeft = await pixel(path, 8, 8);
    final bottomRight = await pixel(path, 1015, 1015);
    final rowWhite = await pixel(path, 300, 348); // inside first white row
    final glyphGap = await pixel(path, 512, 420); // between rows: background
    final dot = await pixel(path, 744, 348); // accent dot
    stdout.writeln('topLeft=$topLeft (expect ~103,80,164)');
    stdout.writeln('bottomRight=$bottomRight (expect ~59,70,205)');
    stdout.writeln('rowWhite=$rowWhite (expect ~255,255,255)');
    stdout.writeln('glyphGap=$glyphGap (gradient, dark purple-blue)');
    stdout.writeln('dot=$dot (expect ~255,214,231)');

    // Alpha channel must be opaque everywhere (App Store requirement).
    final bytes = File(path).readAsBytesSync();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final data =
        (await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    var transparent = 0;
    for (var i = 3; i < data.lengthInBytes; i += 4) {
      if (data.getUint8(i) != 255) transparent++;
    }
    stdout.writeln('non-opaque pixels: $transparent');
    expect(transparent, 0);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
