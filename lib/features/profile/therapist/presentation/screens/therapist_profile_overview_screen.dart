import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/constants/routes.dart';
import '../../../../../shared/models/therapist_model.dart';
import '../../../../../shared/models/user_model.dart';
import '../../bloc/therapist_profile_bloc.dart';
import '../../bloc/therapist_profile_state.dart';

class TherapistProfileOverviewScreen extends StatelessWidget {
  const TherapistProfileOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      body: BlocBuilder<TherapistProfileBloc, TherapistProfileState>(
        builder: (context, state) {
          if (state is TherapistProfileLoading ||
              state is TherapistProfileInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          final TherapistModel therapist;
          final UserModel user;

          if (state is TherapistProfileLoaded) {
            therapist = state.therapist;
            user = state.user;
          } else if (state is TherapistProfileUpdateSuccess) {
            therapist = state.therapist;
            user = state.user;
          } else {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _NavBar(onEdit: () => context.push(Routes.therapistProfileEdit)),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _HeroBlock(therapist: therapist),
                      _InfoSection(
                        label: 'Personal Info',
                        children: [
                          _InfoRow(
                            label: 'Email',
                            value: user.email,
                            trailing: _VerifiedBadge(),
                          ),
                          const _InfoDivider(),
                          _InfoRow(
                            label: 'Phone',
                            value: therapist.phone ?? '—',
                          ),
                        ],
                      ),
                      _InfoSection(
                        label: 'Professional',
                        children: [
                          _InfoRow(label: 'Clinic', value: therapist.clinicName),
                          const _InfoDivider(),
                          _InfoRow(
                              label: 'Specialisation',
                              value: therapist.specialisation),
                          const _InfoDivider(),
                          _InfoRow(
                              label: 'Experience',
                              value: therapist.experience?.trim().isNotEmpty ==
                                      true
                                  ? '${therapist.experience!.trim()} years'
                                  : '—'),
                          const _InfoDivider(),
                          _InfoRow(
                            label: 'Licence',
                            value: therapist.licenceNumber,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock_outline,
                                    size: 13, color: AppColors.textDisabled),
                                const SizedBox(width: 4),
                                Text('Legal record',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textDisabled)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      _InfoSection(
                        label: 'Account',
                        children: [
                          _InfoRow(
                            label: 'Member since',
                            value: _formatJoined(user.createdAt),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenMargin,
                            4,
                            AppSpacing.screenMargin,
                            32),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                context.push(Routes.therapistProfileEdit),
                            icon: const Icon(Icons.edit_outlined,
                                size: 16, color: AppColors.textWhite),
                            label: Text(
                              'Edit Profile',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textWhite,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.pillRadius),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatJoined(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

// ─── Nav bar ─────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  const _NavBar({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.screenMargin, topPadding + 12,
          AppSpacing.screenMargin, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Row(
              children: [
                const Icon(Icons.chevron_left,
                    size: 22, color: AppColors.secondary),
                Text('Back',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    )),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Text('Profile',
                  style: AppTextStyles.heading2.copyWith(
                      color: AppColors.textMain)),
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Text('Edit',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                )),
          ),
        ],
      ),
    );
  }
}

// ─── Hero block ───────────────────────────────────────────────

class _HeroBlock extends StatelessWidget {
  const _HeroBlock({required this.therapist});

  final TherapistModel therapist;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(therapist.name);
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 22),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
      ),
      child: Column(
        children: [
          _AvatarCircle(initials: initials, size: 82),
          const SizedBox(height: 10),
          Text(therapist.name,
              style: AppTextStyles.heading1.copyWith(color: AppColors.textMain)),
          const SizedBox(height: 4),
          Text('ABA Therapist',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPlaceholder)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatPill(value: '0', label: 'Patients',
                  color: AppColors.primary),
              const SizedBox(width: 10),
              _StatPill(
                value: therapist.experience ?? '—',
                label: 'Experience',
                color: AppColors.secondary,
              ),
              const SizedBox(width: 10),
              _StatPill(value: 'Active', label: 'Status',
                  color: AppColors.success),
            ],
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

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.initials, required this.size});

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
        style: TextStyle(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.32,
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border.all(color: AppColors.dividerLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.tag.copyWith(
                  color: AppColors.textPlaceholder,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Info sections ────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMargin, 14, AppSpacing.screenMargin, 6),
          child: Text(label.toUpperCase(),
              style: AppTextStyles.tag.copyWith(
                  color: AppColors.textDisabled,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08)),
        ),
        Container(
          color: AppColors.surfaceDefault,
          child: Column(children: children),
        ),
        const Divider(
            height: 1,
            indent: AppSpacing.screenMargin,
            endIndent: AppSpacing.screenMargin,
            color: AppColors.dividerLight),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDisabled,
                      letterSpacing: 0.02,
                    )),
                const SizedBox(height: 3),
                Text(value,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 1,
        indent: AppSpacing.screenMargin,
        endIndent: AppSpacing.screenMargin,
        color: AppColors.dividerLight);
  }
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text('Verified',
          style: AppTextStyles.tag.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
          )),
    );
  }
}
