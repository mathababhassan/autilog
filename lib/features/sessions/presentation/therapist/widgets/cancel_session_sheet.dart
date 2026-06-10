import 'package:flutter/material.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../shared/models/session_model.dart';

class CancelSessionSheet extends StatelessWidget {
  const CancelSessionSheet({super.key, required this.session});

  final SessionModel session;

  String _summaryLine() {
    final d = session.scheduledAt;
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final t = TimeOfDay.fromDateTime(d);
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month]}'
        ' · $hour:$minute $period · ${session.mode}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceModal,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.sheetRadius),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.screenMargin,
        right: AppSpacing.screenMargin,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.dividerLight,
              borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.textWhite,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Cancel Session?', style: AppTextStyles.heading2),
          const SizedBox(height: AppSpacing.sm),

          SizedBox(
            width: 300,
            child: Text(
              "This will cancel the session and notify the parent. This can't be undone.",
              style: AppTextStyles.body.copyWith(color: AppColors.textPlaceholder),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  '${session.childName} · ${session.type}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs2),
                Text(
                  _summaryLine(),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textDisabled),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl2),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.textWhite,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: Text(
                'Cancel Session',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Keep Session',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
