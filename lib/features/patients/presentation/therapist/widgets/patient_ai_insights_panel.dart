import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/theme.dart';

/// Expanded AI Insights panel (therapist patient detail).
class PatientAiInsightsPanel extends StatefulWidget {
  const PatientAiInsightsPanel({super.key, required this.patientFirstName});

  final String patientFirstName;

  @override
  State<PatientAiInsightsPanel> createState() => _PatientAiInsightsPanelState();
}

class _PatientAiInsightsPanelState extends State<PatientAiInsightsPanel> {
  bool _use30Day = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.primary20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _PeriodToggle(
                use30Day: _use30Day,
                onChanged: (v) => setState(() => _use30Day = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _ChartCard(
            title: 'Progress Over Time',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendRow(items: const [
                  _LegendItem(color: AppColors.error, label: 'Incident Severity'),
                  _LegendItem(color: AppColors.success, label: 'Sleep Quality'),
                ]),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 140,
                  child: CustomPaint(
                    painter: _LineChartPainter(
                      redValues: const [3.2, 2.8, 4.1, 3.5, 2.9, 3.8, 3.0],
                      greenValues: const [4.0, 3.5, 3.8, 4.2, 3.9, 4.5, 4.1],
                    ),
                    size: Size.infinite,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const _WeekdayLabels(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ChartCard(
            title: 'Incidents by Time of Day',
            child: SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _TimeBar(label: 'Morning', value: 1, max: 3),
                  _TimeBar(label: 'Afternoon', value: 3, max: 3),
                  _TimeBar(label: 'Evening', value: 2, max: 3),
                  _TimeBar(label: 'Night', value: 1, max: 3),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ChartCard(
            title: 'Top Triggers',
            child: Column(
              children: const [
                _HorizontalBar(label: 'Transitioning', value: 6, max: 6),
                SizedBox(height: AppSpacing.sm),
                _HorizontalBar(label: 'Loud Noise', value: 4, max: 6),
                SizedBox(height: AppSpacing.sm),
                _HorizontalBar(
                  label: 'Screen Time Ended',
                  value: 1,
                  max: 6,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ChartCard(
            title: 'Consequence Effectiveness',
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      segments: const [
                        _DonutSegment(0.45, AppColors.secondary),
                        _DonutSegment(0.27, AppColors.primary),
                        _DonutSegment(0.28, AppColors.error),
                      ],
                      centerLabel: '72%',
                      subLabel: 'effective',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _DonutLegend(
                        color: AppColors.secondary,
                        label: 'Redirection',
                        percent: '45%',
                      ),
                      SizedBox(height: 6),
                      _DonutLegend(
                        color: AppColors.primary,
                        label: 'Deep Breathing',
                        percent: '27%',
                      ),
                      SizedBox(height: 6),
                      _DonutLegend(
                        color: AppColors.error,
                        label: 'Time Out',
                        percent: '28%',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceDefault,
              borderRadius: BorderRadius.circular(AppSpacing.md),
              border: Border.all(color: AppColors.borderInactive),
            ),
            child: Row(
              children: [
                Text(
                  '8',
                  style: AppTextStyles.display.copyWith(
                    color: AppColors.success,
                    fontSize: 36,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'positive moments this period',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.arrow_upward,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Up from 5 last period',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceDefault,
              borderRadius: BorderRadius.circular(AppSpacing.md),
              border: Border.all(color: AppColors.borderInactive),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary20,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Summary',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${widget.patientFirstName} showed great progress this week with '
                        'transitioning between activities. Minor incidents observed '
                        'during end of screen time. Focus: sleep routine reinforcement.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPlaceholder,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.use30Day, required this.onChanged});

  final bool use30Day;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PeriodChip(
            label: '7D',
            selected: !use30Day,
            onTap: () => onChanged(false),
          ),
          _PeriodChip(
            label: '30D',
            selected: use30Day,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceDefault : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.textMain : AppColors.textPlaceholder,
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class _LegendItem {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.items});
  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      children: items
          .map(
            (i) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  i.label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPlaceholder,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels();

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _days
          .map(
            (d) => Text(
              d,
              style: AppTextStyles.tag.copyWith(
                color: AppColors.textPlaceholder,
                fontSize: 10,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TimeBar extends StatelessWidget {
  const _TimeBar({
    required this.label,
    required this.value,
    required this.max,
  });

  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 80 * (value / max),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.tag.copyWith(
              color: AppColors.textPlaceholder,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HorizontalBar extends StatelessWidget {
  const _HorizontalBar({
    required this.label,
    required this.value,
    required this.max,
  });

  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPlaceholder,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value / max,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$value',
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _DonutLegend extends StatelessWidget {
  const _DonutLegend({
    required this.color,
    required this.label,
    required this.percent,
  });

  final Color color;
  final String label;
  final String percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label, style: AppTextStyles.caption),
        ),
        Text(
          percent,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textPlaceholder,
          ),
        ),
      ],
    );
  }
}

class _DonutSegment {
  const _DonutSegment(this.fraction, this.color);
  final double fraction;
  final Color color;
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.redValues, required this.greenValues});

  final List<double> redValues;
  final List<double> greenValues;

  @override
  void paint(Canvas canvas, Size size) {
    const minY = 1.0;
    const maxY = 5.0;
    final paintGrid = Paint()
      ..color = AppColors.borderInactive.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = size.height * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    void drawLine(List<double> values, Color color) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      for (var i = 0; i < values.length; i++) {
        final x = size.width * i / (values.length - 1);
        final normalized = (values[i] - minY) / (maxY - minY);
        final y = size.height * (1 - normalized);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    drawLine(redValues, AppColors.error);
    drawLine(greenValues, AppColors.success);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.centerLabel,
    required this.subLabel,
  });

  final List<_DonutSegment> segments;
  final String centerLabel;
  final String subLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const stroke = 14.0;
    var start = -math.pi / 2;

    for (final seg in segments) {
      final sweep = 2 * math.pi * seg.fraction;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - stroke / 2),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }

    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: centerLabel,
            style: AppTextStyles.subtitle.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          TextSpan(
            text: '\n$subLabel',
            style: AppTextStyles.tag.copyWith(
              color: AppColors.textPlaceholder,
              fontSize: 10,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: radius);
    tp.paint(
      canvas,
      center - Offset(tp.width / 2, tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
