import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

class LockedStateBadge extends StatelessWidget {
  const LockedStateBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.xl5,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border.all(color: AppColors.borderInactive),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 24,
            color: AppColors.textPlaceholder,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This log is locked',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Behavioral incident logs are locked after 24 hours. '
            'If something looks wrong, you can delete the log or let '
            'your therapist know so they can note it in their next comment.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPlaceholder,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
