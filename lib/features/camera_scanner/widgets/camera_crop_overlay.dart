import 'package:flutter/material.dart';

class CameraCropOverlay extends StatelessWidget {
  final Rect scanWindow;

  const CameraCropOverlay({
    super.key,
    required this.scanWindow,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _OverlayPainter(scanWindow: scanWindow),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect scanWindow;

  _OverlayPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    // Cutout path (inverted mask)
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)));

    final combinedPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(combinedPath, backgroundPaint);

    // Border of scan window
    final borderPaint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)),
      borderPaint,
    );

    // Draw 4 corner accents
    final cornerPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;

    // Top-Left
    canvas.drawLine(
      Offset(scanWindow.left, scanWindow.top + cornerLength),
      Offset(scanWindow.left, scanWindow.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanWindow.left, scanWindow.top),
      Offset(scanWindow.left + cornerLength, scanWindow.top),
      cornerPaint,
    );

    // Top-Right
    canvas.drawLine(
      Offset(scanWindow.right - cornerLength, scanWindow.top),
      Offset(scanWindow.right, scanWindow.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanWindow.right, scanWindow.top),
      Offset(scanWindow.right, scanWindow.top + cornerLength),
      cornerPaint,
    );

    // Bottom-Left
    canvas.drawLine(
      Offset(scanWindow.left, scanWindow.bottom - cornerLength),
      Offset(scanWindow.left, scanWindow.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanWindow.left, scanWindow.bottom),
      Offset(scanWindow.left + cornerLength, scanWindow.bottom),
      cornerPaint,
    );

    // Bottom-Right
    canvas.drawLine(
      Offset(scanWindow.right - cornerLength, scanWindow.bottom),
      Offset(scanWindow.right, scanWindow.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanWindow.right, scanWindow.bottom),
      Offset(scanWindow.right, scanWindow.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow;
  }
}
