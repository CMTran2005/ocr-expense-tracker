import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

class BarChartPainter extends CustomPainter {
  final Map<DateTime, double> weeklyData;
  final double animationProgress;
  final Color barColor;
  final Color activeBarColor;
  final Color gridColor;

  BarChartPainter({
    required this.weeklyData,
    required this.animationProgress,
    this.barColor = const Color(0xFF3B82F6),
    this.activeBarColor = const Color(0xFF10B981),
    this.gridColor = const Color(0xFF334155),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weeklyData.isEmpty) return;

    final double bottomPadding = 26.0;
    final double topPadding = 16.0;
    final double chartHeight = size.height - bottomPadding - topPadding;
    final double chartWidth = size.width;

    final values = weeklyData.values.toList();
    final dates = weeklyData.keys.toList();
    final int count = values.length;

    // Find maximum amount for normalization
    double maxAmount = values.fold<double>(
      0.0,
      (prev, curr) => max(prev, curr),
    );
    if (maxAmount <= 0) maxAmount = 100000; // Default scale if empty

    final double slotWidth = chartWidth / count;
    final double barWidth = min(slotWidth * 0.45, 24.0);

    // Draw baseline
    final linePaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;
    final baselineY = size.height - bottomPadding;
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(chartWidth, baselineY),
      linePaint,
    );

    // Draw dashed 50% guide line
    final dashPaint = Paint()
      ..color = gridColor.withOpacity(0.5)
      ..strokeWidth = 1.0;
    final midY = topPadding + (chartHeight / 2);
    _drawDashedLine(
      canvas,
      Offset(0, midY),
      Offset(chartWidth, midY),
      dashPaint,
    );

    final today = DateTime.now();

    for (int i = 0; i < count; i++) {
      final date = dates[i];
      final amount = values[i];
      final isToday =
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      final double centerX = (i * slotWidth) + (slotWidth / 2);

      // Height calculation with animation
      final double normalizedRatio = (amount / maxAmount).clamp(0.0, 1.0);
      final double currentHeight = max(
        4.0,
        normalizedRatio * chartHeight * animationProgress,
      );
      final double barTop = baselineY - currentHeight;

      // Draw Bar
      final barRect = Rect.fromCenter(
        center: Offset(centerX, barTop + (currentHeight / 2)),
        width: barWidth,
        height: currentHeight,
      );

      final barPaint = Paint()
        ..color = isToday
            ? activeBarColor
            : (amount > 0 ? barColor : const Color(0xFF1E293B))
        ..style = PaintingStyle.fill;

      final roundedRect = RRect.fromRectAndCorners(
        barRect,
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
        bottomLeft: const Radius.circular(2),
        bottomRight: const Radius.circular(2),
      );

      canvas.drawRRect(roundedRect, barPaint);

      // Draw Day Label (e.g., T2, T3, T4... CN)
      final label = _getDayLabel(date);
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: isToday ? activeBarColor : const Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(centerX - (textPainter.width / 2), baselineY + 6),
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 4;
    const double dashSpace = 4;
    double startX = p1.dx;
    final double y = p1.dy;
    while (startX < p2.dx) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(min(startX + dashWidth, p2.dx), y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  String _getDayLabel(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return DateFormat('E').format(date);
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.weeklyData != weeklyData;
  }
}
