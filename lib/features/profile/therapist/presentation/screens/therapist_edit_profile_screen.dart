import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../shared/models/therapist_model.dart';
import '../../../../../shared/models/user_model.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/app_snackbar.dart';
import '../../../../../shared/widgets/app_confirmation_dialog.dart';
import '../../bloc/therapist_profile_bloc.dart';
import '../../bloc/therapist_profile_event.dart';
import '../../bloc/therapist_profile_state.dart';

class TherapistEditProfileScreen extends StatefulWidget {
  const TherapistEditProfileScreen({super.key});

  @override
  State<TherapistEditProfileScreen> createState() =>
      _TherapistEditProfileScreenState();
}

class _TherapistEditProfileScreenState
    extends State<TherapistEditProfileScreen> {
  late TextEditingController _phoneCtrl;
  late TextEditingController _clinicCtrl;
  late TextEditingController _specialisationCtrl;
  late TextEditingController _experienceCtrl;

  late TherapistModel _original;
  late UserModel _originalUser;
  bool _initialised = false;

  bool get _isDirty {
    if (!_initialised) return false;
    return _phoneCtrl.text != (_original.phone ?? '') ||
        _clinicCtrl.text != _original.clinicName ||
        _specialisationCtrl.text != _original.specialisation ||
        _experienceCtrl.text != (_original.experience ?? '');
  }

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController();
    _clinicCtrl = TextEditingController();
    _specialisationCtrl = TextEditingController();
    _experienceCtrl = TextEditingController();

    _phoneCtrl.addListener(() => setState(() {}));
    _clinicCtrl.addListener(() => setState(() {}));
    _specialisationCtrl.addListener(() => setState(() {}));
    _experienceCtrl.addListener(() => setState(() {}));
  }

  void _initFromState(TherapistModel therapist, UserModel user) {
    if (_initialised) return;
    _original = therapist;
    _originalUser = user;
    _phoneCtrl.text = therapist.phone ?? '';
    _clinicCtrl.text = therapist.clinicName;
    _specialisationCtrl.text = therapist.specialisation;
    _experienceCtrl.text = therapist.experience ?? '';
    _initialised = true;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _clinicCtrl.dispose();
    _specialisationCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_isDirty) return;

    final clinicName = _clinicCtrl.text.trim();
    final specialisation = _specialisationCtrl.text.trim();

    if (clinicName.isEmpty || specialisation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Clinic name and specialisation cannot be empty.'),
        ),
      );
      return;
    }

    final fields = <String, dynamic>{
      'clinicName': clinicName,
      'specialisation': specialisation,
    };
    final phone = _phoneCtrl.text.trim();
    if (phone.isNotEmpty) fields['phone'] = phone;
    final experience = _experienceCtrl.text.trim();
    if (experience.isNotEmpty) fields['experience'] = experience;

    context.read<TherapistProfileBloc>().add(
      TherapistProfileUpdateRequested(fields: fields),
    );
  }

  Future<void> _confirmSignOut() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _SignOutSheet(
        onConfirm: () {
          Navigator.of(sheetCtx).pop();
          context.read<TherapistProfileBloc>().add(
            const TherapistProfileSignOutRequested(),
          );
        },
        onCancel: () => Navigator.of(sheetCtx).pop(),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    const consentText =
        'I consent to deleting my therapist profile with all its data';
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Delete account?',
      description:
          'This will permanently delete your profile, all linked patient data, and your login. This cannot be undone.',
      confirmText: consentText,
      confirmButtonLabel: 'Delete Account',
    );
    if (confirmed == true && mounted) {
      context.read<TherapistProfileBloc>().add(
        const TherapistProfileDeleteRequested(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TherapistProfileBloc, TherapistProfileState>(
      listener: (context, state) {
        if (state is TherapistProfileUpdateSuccess) {
          AppSnackbar.showSuccess(context, 'Profile updated successfully.');
          context.pop();
        } else if (state is TherapistProfileError) {
          AppSnackbar.showError(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is TherapistProfileLoaded) {
          _initFromState(state.therapist, state.user);
        } else if (state is TherapistProfileUpdating) {
          _initFromState(state.therapist, state.user);
        } else if (state is TherapistProfileUpdateSuccess) {
          _initFromState(state.therapist, state.user);
        }

        final isSaving =
            state is TherapistProfileUpdating ||
            state is TherapistProfileDeleting;

        if (!_initialised) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.surfaceDefault,
          body: Column(
            children: [
              _NavBar(
                isDirty: _isDirty,
                isSaving: isSaving,
                onBack: () => context.pop(),
                onSave: _save,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AvatarBlock(name: _original.name),
                      _EditSection(
                        label: 'Personal Info',
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screenMargin,
                              10,
                              AppSpacing.screenMargin,
                              10,
                            ),
                            child: AppTextField(
                              label: 'Phone Number',
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const Divider(
                            height: 1,
                            indent: AppSpacing.screenMargin,
                            endIndent: AppSpacing.screenMargin,
                            color: AppColors.dividerLight,
                          ),
                          _ReadOnlyRow(
                            label: 'Email Address',
                            value: _originalUser.email,
                            note: 'Verified — contact support to change',
                          ),
                        ],
                      ),
                      _EditSection(
                        label: 'Professional',
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screenMargin,
                              10,
                              AppSpacing.screenMargin,
                              0,
                            ),
                            child: Column(
                              children: [
                                AppTextField(
                                  label: 'Clinic Name',
                                  controller: _clinicCtrl,
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  label: 'Specialisation',
                                  controller: _specialisationCtrl,
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  label: 'Years of Experience',
                                  controller: _experienceCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                          const Divider(
                            height: 1,
                            indent: AppSpacing.screenMargin,
                            endIndent: AppSpacing.screenMargin,
                            color: AppColors.dividerLight,
                          ),
                          _ReadOnlyRow(
                            label: 'Licence Number',
                            value: _original.licenceNumber,
                            note: 'Legal record — cannot be changed',
                          ),
                        ],
                      ),
                      _EditSection(
                        label: 'Account',
                        children: [
                          _ActionRow(
                            label: 'Change Password',
                            color: AppColors.secondary,
                            showChevron: true,
                            onTap: () {},
                          ),
                          const Divider(
                            height: 1,
                            indent: AppSpacing.screenMargin,
                            endIndent: AppSpacing.screenMargin,
                            color: AppColors.dividerLight,
                          ),
                          _ActionRow(
                            label: 'Sign Out',
                            color: AppColors.error,
                            onTap: isSaving ? null : _confirmSignOut,
                          ),
                          const Divider(
                            height: 1,
                            indent: AppSpacing.screenMargin,
                            endIndent: AppSpacing.screenMargin,
                            color: AppColors.dividerLight,
                          ),
                          _ActionRow(
                            label: 'Delete Account',
                            color: AppColors.error,
                            onTap: isSaving ? null : _confirmDelete,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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

// ─── Nav bar ─────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.isDirty,
    required this.isSaving,
    required this.onBack,
    required this.onSave,
  });

  final bool isDirty;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        topPadding + 12,
        AppSpacing.screenMargin,
        12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Row(
              children: [
                const Icon(
                  Icons.chevron_left,
                  size: 22,
                  color: AppColors.secondary,
                ),
                Text(
                  'Back',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Edit Profile',
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.textMain,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: isDirty && !isSaving ? onSave : null,
            child: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.secondary,
                    ),
                  )
                : Text(
                    'Save',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDirty
                          ? AppColors.secondary
                          : AppColors.textDisabled,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Avatar block ─────────────────────────────────────────────

class _AvatarBlock extends StatelessWidget {
  const _AvatarBlock({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? ''
        : parts.length == 1
        ? parts[0][0].toUpperCase()
        : '${parts[0][0]}${parts[1][0]}'.toUpperCase();

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w700,
                fontSize: 26,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {},
            child: Text(
              'Change Photo',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section wrapper ──────────────────────────────────────────

class _EditSection extends StatelessWidget {
  const _EditSection({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            14,
            AppSpacing.screenMargin,
            6,
          ),
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.tag.copyWith(
              color: AppColors.textDisabled,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
            ),
          ),
        ),
        Container(
          color: AppColors.surfaceDefault,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
        const Divider(
          height: 1,
          indent: AppSpacing.screenMargin,
          endIndent: AppSpacing.screenMargin,
          color: AppColors.dividerLight,
        ),
      ],
    );
  }
}

// ─── Read-only row ────────────────────────────────────────────

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.7,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin,
          vertical: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.tag.copyWith(
                    color: AppColors.textDisabled,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.04,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.lock_outline,
                  size: 12,
                  color: AppColors.textDisabled,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.subtitle.copyWith(color: AppColors.textMain),
            ),
            const SizedBox(height: 2),
            Text(
              note,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action row ───────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.color,
    required this.onTap,
    this.showChevron = false,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin,
          vertical: 14,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textDisabled,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Sign Out bottom sheet ────────────────────────────────────

class _SignOutSheet extends StatelessWidget {
  const _SignOutSheet({required this.onConfirm, required this.onCancel});

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sign out?',
              style: AppTextStyles.heading2.copyWith(color: AppColors.textMain),
            ),
            const SizedBox(height: 8),
            Text(
              "You'll need to sign back in to access your patients and sessions.",
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPlaceholder,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                ),
                child: Text(
                  'Sign Out',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onCancel,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: Center(
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
