import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../core/theme/theme.dart';

/// P19 header AppBar — orange bar with logo and profile avatar.
class LogFormAppBar extends StatelessWidget {
  const LogFormAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        0,
        AppSpacing.screenMargin,
        AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/autilog_logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'AutiLog',
                style: AppTextStyles.subtitle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textWhite,
                  height: 20 / 16,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => context.push(Routes.parentProfile),
            child: Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary40,
                border: Border.all(color: AppColors.primary, width: 2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 24,
                color: AppColors.textWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
