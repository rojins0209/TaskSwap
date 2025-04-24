import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PlaceholderImageGenerator {
  static Future<Uint8List> generatePlaceholderImage({
    required String text,
    required Color color,
    double width = 300,
    double height = 300,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Draw background
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);

    // Draw icon or text
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: width);
    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        (height - textPainter.height) / 2,
      ),
    );

    // Convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static Future<void> saveOnboardingPlaceholders() async {
    // This would be used to save the images to the assets folder
    // But for now, we'll just use the error builder in the onboarding screen
  }
}
