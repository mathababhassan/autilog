import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../features/auth/bloc/therapist_registration_bloc.dart';
import '../../../../../features/auth/data/auth_repository.dart';
import '../../../../../shared/widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry point
// ─────────────────────────────────────────────────────────────────────────────

class TherapistRegistrationScreen extends StatelessWidget {
  const TherapistRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => TherapistRegistrationBloc(
        authRepository: ctx.read<AuthRepository>(),
      ),
      child: const _RegistrationView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View
// ─────────────────────────────────────────────────────────────────────────────

class _RegistrationView extends StatefulWidget {
  const _RegistrationView();

  @override
  State<_RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<_RegistrationView> {
  final _scrollController = ScrollController();

  final _nameKey = GlobalKey();
  final _emailKey = GlobalKey();
  final _passwordKey = GlobalKey();
  final _licenceKey = GlobalKey();
  final _clinicKey = GlobalKey();
  final _specKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToFirstError(TherapistRegistrationState state) {
    final firstKey = [
      if (state.nameError != null) _nameKey,
      if (state.emailError != null) _emailKey,
      if (state.passwordError != null) _passwordKey,
      if (state.licenceError != null) _licenceKey,
      if (state.clinicError != null) _clinicKey,
      if (state.specialisationError != null) _specKey,
    ].firstOrNull;

    if (firstKey?.currentContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Scrollable.ensureVisible(
          firstKey!.currentContext!,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TherapistRegistrationBloc, TherapistRegistrationState>(
      listener: (context, state) {
        if (state.status == FormzSubmissionStatus.failure &&
            state.serverError != null) {
          AppSnackbar.showError(context, state.serverError!);
        } else {
          _scrollToFirstError(state);
        }
      },
      builder: (context, state) {
        final bloc = context.read<TherapistRegistrationBloc>();
        final isSubmitting =
            state.status == FormzSubmissionStatus.inProgress;
        final topPadding = MediaQuery.of(context).padding.top;

        return Scaffold(
          backgroundColor: AppColors.surfaceDefault,
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── Collapsing orange banner ─────────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _BannerDelegate(
                  topPadding: topPadding,
                  onBack: () => context.canPop()
                      ? context.pop()
                      : context.go(Routes.login),
                ),
              ),

              // ── Form content ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin,
                    vertical: AppSpacing.xl2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Account',
                        style: AppTextStyles.heading1,
                      ),
                      const SizedBox(height: AppSpacing.xl2),

                      // Full Name
                      AppTextField(
                        key: _nameKey,
                        label: 'Full Name',
                        errorText: state.nameError,
                        textInputAction: TextInputAction.next,
                        onChanged: (v) =>
                            bloc.add(TherapistRegistrationNameChanged(v)),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Email
                      AppTextField(
                        key: _emailKey,
                        label: 'Email Address',
                        keyboardType: TextInputType.emailAddress,
                        errorText: state.emailError,
                        textInputAction: TextInputAction.next,
                        onChanged: (v) =>
                            bloc.add(TherapistRegistrationEmailChanged(v)),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Password
                      AppTextField(
                        key: _passwordKey,
                        label: 'Password',
                        obscureText: true,
                        errorText: state.passwordError,
                        textInputAction: TextInputAction.next,
                        onChanged: (v) =>
                            bloc.add(TherapistRegistrationPasswordChanged(v)),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Gender (UI-only)
                      _GenderField(
                        selected: state.gender,
                        onChanged: (v) =>
                            bloc.add(TherapistRegistrationGenderChanged(v)),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Licence Number
                      AppTextField(
                        key: _licenceKey,
                        label: 'Licence Number',
                        errorText: state.licenceError,
                        textInputAction: TextInputAction.next,
                        onChanged: (v) =>
                            bloc.add(TherapistRegistrationLicenceChanged(v)),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Clinic Name
                      AppTextField(
                        key: _clinicKey,
                        label: 'Clinic Name',
                        errorText: state.clinicError,
                        textInputAction: TextInputAction.next,
                        onChanged: (v) =>
                            bloc.add(TherapistRegistrationClinicChanged(v)),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Specialisation dropdown
                      _SpecialisationDropdown(
                        fieldKey: _specKey,
                        value: state.specialisation.isEmpty
                            ? null
                            : state.specialisation,
                        errorText: state.specialisationError,
                        onChanged: (v) {
                          if (v != null) {
                            bloc.add(TherapistRegistrationSpecialisationChanged(v));
                          }
                        },
                      ),

                      // ── CTA ─────────────────────────────────────────────
                      const SizedBox(height: AppSpacing.xl3),
                      AppPrimaryButton(
                        label: 'Create Account',
                        borderRadius: 30,
                        isLoading: isSubmitting,
                        onPressed: isSubmitting
                            ? null
                            : () =>
                                bloc.add(const TherapistRegistrationSubmitted()),
                      ),

                      // ── Footer ──────────────────────────────────────────
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: 'Already have an account? ',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPlaceholder,
                            ),
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: GestureDetector(
                                  onTap: () =>
                                      context.go(Routes.login),
                                  child: Text(
                                    'Log in',
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom safe-area breathing room
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom +
                            AppSpacing.lg,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Collapsing banner — SliverPersistentHeaderDelegate
// ─────────────────────────────────────────────────────────────────────────────

class _BannerDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final VoidCallback onBack;

  _BannerDelegate({required this.topPadding, required this.onBack});

  static const double _expandedHeight = 200;
  static const double _maxRadius = 56.0;

  @override
  double get maxExtent => _expandedHeight + topPadding;

  @override
  double get minExtent => kToolbarHeight + topPadding;

  @override
  bool shouldRebuild(_BannerDelegate old) => old.topPadding != topPadding;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress =
        (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final radius = _maxRadius * (1 - progress);
    // Subtitle fades out in the first 40 % of the collapse travel.
    final subtitleOpacity = (1 - progress / 0.4).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      child: Container(
        color: AppColors.primary,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Large decorative circle — top right
            Positioned(
              right: -20,
              top: 0,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceDefault.withValues(alpha: 0.15),
                ),
              ),
            ),
            // Small decorative circle
            Positioned(
              right: 110,
              top: 10,
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceDefault.withValues(alpha: 0.12),
                ),
              ),
            ),
            // Subtitle — fades out early in the collapse
            if (subtitleOpacity > 0)
              Positioned(
                left: AppSpacing.screenMargin,
                right: 130,
                top: topPadding + kToolbarHeight + AppSpacing.sm,
                child: Opacity(
                  opacity: subtitleOpacity,
                  child: Text(
                    'Register as a therapist to get started',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textWhite),
                  ),
                ),
              ),
            // Toolbar row: back arrow + title
            Positioned(
              left: 0,
              right: 0,
              top: topPadding,
              height: kToolbarHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: onBack,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 56,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.screenMargin,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SvgPicture.asset(
                            'assets/icons/icon_back.svg',
                            width: 10,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              AppColors.textWhite,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Register As Therapist',
                    style: AppTextStyles.heading2
                        .copyWith(color: AppColors.textWhite),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gender radio row
// ─────────────────────────────────────────────────────────────────────────────

class _GenderField extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onChanged;

  const _GenderField({required this.selected, required this.onChanged});

  static const _options = ['Male', 'Female', 'Prefer not to say'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender', style: AppTextStyles.body),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.lg,
          children: _options.map((option) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(
                  value: option,
                  groupValue: selected,
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: (v) {
                    if (v != null) onChanged(v);
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(option, style: AppTextStyles.body),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Specialisation dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _SpecialisationDropdown extends StatelessWidget {
  final Key? fieldKey;
  final String? value;
  final String? errorText;
  final ValueChanged<String?> onChanged;

  static const _options = [
    'ABA Therapist',
    'Behavioral Specialist',
    'Psychologist',
    'Other',
  ];

  const _SpecialisationDropdown({
    this.fieldKey,
    this.value,
    this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: fieldKey,
      initialValue: value,
      isExpanded: true,
      style: AppTextStyles.body.copyWith(color: AppColors.textMain),
      decoration: InputDecoration(
        labelText: 'Specialisation',
        labelStyle:
            AppTextStyles.body.copyWith(color: AppColors.textPlaceholder),
        floatingLabelStyle: AppTextStyles.body.copyWith(
          fontSize: 14,
          color: errorText != null
              ? AppColors.error
              : AppColors.textPlaceholder,
        ),
        errorText: errorText,
        errorStyle:
            AppTextStyles.caption.copyWith(color: AppColors.error),
        filled: true,
        fillColor: value != null
            ? AppColors.inputFill
            : AppColors.surfaceDefault,
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppSpacing.borderRadius),
          borderSide: value != null
              ? BorderSide.none
              : const BorderSide(color: AppColors.borderInactive),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppSpacing.borderRadius),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppSpacing.borderRadius),
          borderSide:
              const BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppSpacing.borderRadius),
          borderSide:
              const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      items: _options
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(s, style: AppTextStyles.body),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
