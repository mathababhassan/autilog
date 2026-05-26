import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

class IncidentSavedDialog extends StatelessWidget {
  final String patientName;
  final String time;
  final String? therapistName;
  final VoidCallback onBackToLogs;
  final VoidCallback onLogAnother;

  const IncidentSavedDialog({
    super.key,
    required this.patientName,
    required this.time,
    this.therapistName,
    required this.onBackToLogs,
    required this.onLogAnother,
  });

  @override
  Widget build(BuildContext context) {
    final body = therapistName != null
        ? "$patientName's incident for today at $time has been saved. "
            "$therapistName can now review it in the app."
        : "$patientName's incident for today at $time has been saved.";

    return Dialog(
      backgroundColor: AppColors.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
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
                color: AppColors.secondary20,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.secondary,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Incident Logged successfully',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
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
                onPressed: onBackToLogs,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                ),
                child: Text(
                  'Back to logs',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: onLogAnother,
              child: Text(
                'Log another incident',
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
