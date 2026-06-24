import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/constants/routes.dart';
import '../../bloc/therapist_profile_bloc.dart';
import '../../bloc/therapist_profile_event.dart';
import '../../bloc/therapist_profile_state.dart';

Future<void> showTherapistProfileSheet(BuildContext context, {String? preloadedName, String? preloadedClinic}) {
    return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceModal,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => BlocProvider.value(
      value: context.read<TherapistProfileBloc>(),
      child: const _TherapistProfileSheet(),
    ),
  );
}

class _TherapistProfileSheet extends StatelessWidget {
  const _TherapistProfileSheet();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TherapistProfileBloc, TherapistProfileState>(
      listener: (context, state) {
        if (state is TherapistProfileSignedOut ||
            state is TherapistProfileDeleted) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final String name;
        final String subtitle;
        final String initials;

        if (state is TherapistProfileLoaded) {
          name = state.therapist.name;
          subtitle = 'ABA Therapist · ${state.therapist.clinicName}';
          initials = _initials(name);
        } else if (state is TherapistProfileUpdateSuccess) {
          name = state.therapist.name;
          subtitle = 'ABA Therapist · ${state.therapist.clinicName}';
          initials = _initials(name);
        } else if (state is TherapistProfileUpdating) {
          name = state.therapist.name;
          subtitle = 'ABA Therapist · ${state.therapist.clinicName}';
          initials = _initials(name);
        } else {
          return const SafeArea(
            top: false,
            child: SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grabber
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.dividerLight,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),

              // Identity block
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
                child: Row(
                  children: [
                    _Avatar(initials: initials, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTextStyles.subtitle.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPlaceholder,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.dividerLight),

              // Actions
              _SheetRow(
                icon: SvgPicture.asset(
                  'assets/icons/profile_outline.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textMain,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'View Profile',
                iconBoxColor: AppColors.inputFill,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push(Routes.therapistProfile);
                },
              ),
              const Divider(
                height: 1,
                indent: 22,
                endIndent: 22,
                color: AppColors.dividerLight,
              ),
              _SheetRow(
                icon: SvgPicture.asset(
                  'assets/icons/edit_outline.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textMain,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Edit Profile',
                iconBoxColor: AppColors.inputFill,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push(Routes.therapistProfileEdit);
                },
              ),
              const Divider(
                height: 1,
                indent: 22,
                endIndent: 22,
                color: AppColors.dividerLight,
              ),
              _SheetRow(
                icon: const Icon(Icons.settings_outlined,
                    size: 20, color: AppColors.textMain),
                label: 'Settings',
                iconBoxColor: AppColors.inputFill,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push(Routes.therapistSettings);
                },
              ),
              const Divider(
                height: 1,
                indent: 22,
                endIndent: 22,
                color: AppColors.dividerLight,
              ),
              _SheetRow(
                icon: SvgPicture.asset(
                  'assets/icons/shield_outline.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textMain,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Change Password',
                iconBoxColor: AppColors.inputFill,
                onTap: () {},
              ),
              const Divider(height: 1, color: AppColors.dividerLight),
              _SheetRow(
                icon: SvgPicture.asset(
                  'assets/icons/signout_outline.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.error,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Sign Out',
                labelColor: AppColors.error,
                iconBoxColor: AppColors.inputFill,
                onTap: () => _confirmSignOut(context),
              ),

              const SizedBox(height: 36),
            ],
          ),
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceModal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        ),
        title: Text(
          'Sign out?',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textMain),
        ),
        content: Text(
          "You'll need to sign back in to access your patients and sessions.",
          style: AppTextStyles.body.copyWith(color: AppColors.textMain),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
              context.read<TherapistProfileBloc>().add(
                const TherapistProfileSignOutRequested(),
              );
            },
            child: Text(
              'Sign Out',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconBoxColor,
    this.labelColor,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconBoxColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBoxColor ?? AppColors.surfaceDefault,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? AppColors.textMain,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.heading2.copyWith(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
