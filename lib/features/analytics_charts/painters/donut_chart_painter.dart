import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/categories.dart';

class DonutChartPainter extends CustomPainter {
  final Map<ExpenseCategory, double> data;
  final double animationProgress;
  final double strokeWidth;
  final Color backgroundColor;

  DonutChartPainter({
    required this.data,
    required this.animationProgress,
    this.strokeWidth = 32.0,
    this.backgroundColor = const Color(0xFF334155),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final total = data.values.fold<double>(0.0, (prev, curr) => prev + curr);

    // If no data, draw background placeholder circle
    if (total == 0 || data.isEmpty) {
      final bgPaint = Paint()
        ..color = backgroundColor.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, bgPaint);
      return;
    }

    double currentAngle = -pi / 2; // Start from top 12 o'clock
    const double gapAngle = 0.04; // Visual gap between donut slices

    final totalSweepBudget = 2 * pi * animationProgress;

    data.forEach((category, amount) {
      if (amount <= 0) return;

      final proportion = amount / total;
      final sweepAngle = (proportion * 2 * pi) * animationProgress;

      // Adjust for slight gap if multiple segments
      final actualSweep = data.length > 1
          ? max(0.0, sweepAngle - gapAngle)
          : sweepAngle;

      final paint = Paint()
        ..color = category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (actualSweep > 0) {
        canvas.drawArc(rect, currentAngle, actualSweep, false, paint);
      }

      currentAngle += sweepAngle;
    });
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.data != data;
  }
}
