import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

class IncidentUpdatedDialog extends StatelessWidget {
  const IncidentUpdatedDialog({
    super.key,
    required this.patientName,
    required this.time,
    required this.onBackToIncident,
  });

  final String patientName;
  final String time;
  final VoidCallback onBackToIncident;

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
              'Incident Updated Successfully',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "$patientName's incident at $time has been updated.",
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
                onPressed: onBackToIncident,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                ),
                child: Text(
                  'Back to incident',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
