import 'package:flutter/material.dart';

import '../../../../../core/theme/theme.dart';

class PatientSessionCard extends StatelessWidget {
  const PatientSessionCard({
    super.key,
    required this.title,
    required this.timeRange,
    required this.location,
  });

  final String title;
  final String timeRange;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border.all(color: AppColors.secondary, width: 1.2),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary20,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textPlaceholder,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeRange,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPlaceholder,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.videocam_outlined,
                    size: 14,
                    color: AppColors.textPlaceholder,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPlaceholder,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
