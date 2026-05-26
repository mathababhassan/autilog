import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/theme.dart';

class VideoCard extends StatelessWidget {
  const VideoCard({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderInactive),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.videocam_outlined,
                size: 20,
                color: AppColors.textMain,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Attached Video', style: AppTextStyles.subtitle),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          GestureDetector(
            onTap: () => context.push(Routes.videoPlayer, extra: videoUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: Container(
                height: 180,
                color: AppColors.borderInactive,
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.textWhite,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs2),
          Text(
            'Tap to play',
            style: AppTextStyles.tag.copyWith(color: AppColors.textPlaceholder),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
