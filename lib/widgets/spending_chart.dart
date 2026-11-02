import 'package:flutter/material.dart';

import '../utils/currency_formatter.dart';

/// Reusable, dependency-free bar chart driven entirely by real saved data.
///
/// Used for:
///  • Dashboard "spending overview" (last 7 days)
///  • Statistics "monthly overview" (last 6 months)
///  • Statistics "daily spending" (current month)
class SpendingChart extends StatelessWidget {
  const SpendingChart({
    super.key,
    required this.labels,
    required this.values,
    this.height = 150,
    this.showValueLabels = false,
    this.animateIntrinsicColors = true,
  });

  /// One label per bar (already formatted by the caller).
  final List<String> labels;

  /// Bar heights; must match [labels] length. All-nonzero series auto-scale.
  final List<double> values;

  final double height;
  final bool showValueLabels;

  /// Paint bars with the theme's primary colour (always) — this flag exists
  /// to visually single out the max bar via opacity differences.
  final bool animateIntrinsicColors;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    assert(
      labels.length == values.length,
      'SpendingChart labels and values must be parallel lists',
    );

    if (values.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data yet',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final double maxValue = values.reduce((double a, double b) => a > b ? a : b);
    final int maxIndex = values.indexOf(maxValue);

    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _BarChartPainter(
          labels: labels,
          values: values,
          maxValue: maxValue <= 0 ? 1 : maxValue,
          maxIndex: maxIndex,
          barColor: scheme.primary,
          trackColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          labelColor: scheme.onSurfaceVariant,
          valueLabelColor: scheme.onSurface,
          textStyle: theme.textTheme.labelSmall!,
          showValueLabels: showValueLabels,
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.labels,
    required this.values,
    required this.maxValue,
    required this.maxIndex,
    required this.barColor,
    required this.trackColor,
    required this.labelColor,
    required this.valueLabelColor,
    required this.textStyle,
    required this.showValueLabels,
  });

  final List<String> labels;
  final List<double> values;
  final double maxValue;
  final int maxIndex;
  final Color barColor;
  final Color trackColor;
  final Color labelColor;
  final Color valueLabelColor;
  final TextStyle textStyle;
  final bool showValueLabels;

  static const double _barSpacing = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final int count = values.length;
    if (count == 0) return;

    const double bottomLabelHeight = 18;
    final double topInset = showValueLabels ? 16 : 4;
    final double plotHeight = size.height - bottomLabelHeight - topInset;
    if (plotHeight <= 0) return;

    final double slot = size.width / count;
    final double barWidth =
        (slot - _barSpacing).clamp(8.0, 46.0).toDouble();

    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < count; i++) {
      final double slotCenter = slot * i + slot / 2;
      final double barH = plotHeight * (values[i] / maxValue).clamp(0.0, 1.0);

      // Track (full-height neutral bar) keeps chart shape readable.
      final Rect trackRect = Rect.fromLTWH(
        slotCenter - barWidth / 2,
        topInset,
        barWidth,
        plotHeight,
      );
      final RRect trackRRect = RRect.fromRectAndCorners(
        trackRect,
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
        bottomLeft: const Radius.circular(6),
        bottomRight: const Radius.circular(6),
      );
      canvas.drawRRect(trackRRect, Paint()..color = trackColor);

      if (values[i] > 0) {
        final Rect barRect = Rect.fromLTWH(
          slotCenter - barWidth / 2,
          topInset + plotHeight - barH,
          barWidth,
          barH,
        );
        final RRect barRRect = RRect.fromRectAndCorners(
          barRect,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
          bottomLeft: const Radius.circular(6),
          bottomRight: const Radius.circular(6),
        );
        // Peak bar fully opaque; others slightly dimmed for hierarchy.
        final Paint paint = Paint()
          ..color = i == maxIndex
              ? barColor
              : barColor.withValues(alpha: 0.85);
        canvas.drawRRect(barRRect, paint);
      }

      // X label under each bar.
      tp.text = TextSpan(text: labels[i], style: textStyle.copyWith(color: labelColor));
      tp.layout(maxWidth: slot + 6);
      tp.paint(
        canvas,
        Offset(slotCenter - tp.width / 2, size.height - bottomLabelHeight),
      );

      // Optional value above the peak bar.
      if (showValueLabels && i == maxIndex && values[i] > 0) {
        final String valueText = CurrencyFormatter.formatShort(values[i]);
        tp.text = TextSpan(
          text: valueText,
          style: textStyle.copyWith(color: valueLabelColor, fontWeight: FontWeight.w700),
        );
        tp.layout(maxWidth: size.width);
        tp.paint(
          canvas,
          Offset(
            slotCenter - tp.width / 2,
            (topInset + plotHeight - barH - 16).clamp(0.0, size.height),
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.labels != labels ||
      oldDelegate.values != values ||
      oldDelegate.maxValue != maxValue ||
      oldDelegate.maxIndex != maxIndex ||
      oldDelegate.barColor != barColor ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.showValueLabels != showValueLabels;
}
