import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../shared/widgets/app_snackbar.dart';

enum TherapistNavTab { home, patients, sessions, reports }

class TherapistBottomNav extends StatelessWidget {
  const TherapistBottomNav({super.key, required this.activeTab});

  final TherapistNavTab activeTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border(top: BorderSide(color: AppColors.dividerLight, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 50,
          child: Row(
            children: [
              _TabItem(
                iconOutline: 'assets/icons/home_outline.svg',
                iconFilled: 'assets/icons/home_filled.svg',
                label: 'Home',
                active: activeTab == TherapistNavTab.home,
                onTap: () => context.go(Routes.therapistHome),
              ),
              _TabItem(
                iconOutline: 'assets/icons/patient_outline.svg',
                iconFilled: 'assets/icons/patient_filled.svg',
                label: 'Patients',
                active: activeTab == TherapistNavTab.patients,
                onTap: () => context.go(Routes.therapistPatients),
              ),
              _TabItem(
                iconOutline: 'assets/icons/session_outline.svg',
                iconFilled: 'assets/icons/session_filled.svg',
                label: 'Sessions',
                active: activeTab == TherapistNavTab.sessions,
                onTap: () =>
                    AppSnackbar.showError(context, 'Sessions coming soon'),
              ),
              _TabItem(
                iconOutline: 'assets/icons/report_outline.svg',
                iconFilled: 'assets/icons/report_filled.svg',
                label: 'Reports',
                active: activeTab == TherapistNavTab.reports,
                onTap: () =>
                    AppSnackbar.showError(context, 'Reports coming soon'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.iconOutline,
    this.iconFilled,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final String iconOutline;
  final String? iconFilled;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = active ? AppColors.primary : AppColors.textHighContrast;
    final asset = active ? (iconFilled ?? iconOutline) : iconOutline;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              asset,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: active ? AppColors.primary : AppColors.textHighContrast,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
