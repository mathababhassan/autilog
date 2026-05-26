import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

class PositiveMomentSavedDialog extends StatelessWidget {
  final String patientName;
  final String time;
  final VoidCallback onBackToHome;
  final VoidCallback? onViewDetail;
  final VoidCallback onLogAnother;

  const PositiveMomentSavedDialog({
    super.key,
    required this.patientName,
    required this.time,
    required this.onBackToHome,
    this.onViewDetail,
    required this.onLogAnother,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primary20,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration_outlined,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Positive moment saved',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "$patientName's positive moment at $time has been saved.",
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPlaceholder,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl2),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: onViewDetail ?? onBackToHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                ),
                child: Text(
                  onViewDetail != null ? 'View positive moment' : 'Back to Home',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (onViewDetail != null) ...[
              TextButton(
                onPressed: onBackToHome,
                child: Text(
                  'Back to Home',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            TextButton(
              onPressed: onLogAnother,
              child: Text(
                'Log another moment',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
