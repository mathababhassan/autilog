import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../shared/models/therapist_model.dart';
import '../../../../../shared/models/user_model.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/app_snackbar.dart';
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

  String? _profilePhotoBase64;
  bool _loadingPhoto = false;

  bool get _isDirty {
    if (!_initialised) return false;
    return _phoneCtrl.text != (_original.phone ?? '') ||
        _clinicCtrl.text != _original.clinicName ||
        _specialisationCtrl.text != _original.specialisation ||
        _experienceCtrl.text != (_original.experience ?? '') ||
        _profilePhotoBase64 != null;
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

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _loadingPhoto = true);
    final bytes = await File(picked.path).readAsBytes();
    setState(() {
      _profilePhotoBase64 = base64Encode(bytes);
      _loadingPhoto = false;
    });
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
      const SnackBar(
        content: Text('Clinic name and specialisation cannot be empty.'),
        backgroundColor: Colors.red,
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
    if (_profilePhotoBase64 != null) fields['profilePhotoBase64'] = _profilePhotoBase64;

    context
        .read<TherapistProfileBloc>()
        .add(TherapistProfileUpdateRequested(fields: fields));
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

        final isSaving = state is TherapistProfileUpdating ||
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
                      _AvatarBlock(
                        name: _original.name,
                        profilePhotoBase64: _profilePhotoBase64,
                        loadingPhoto: _loadingPhoto,
                        onPickPhoto: _pickPhoto,
                      ),
                      _EditSection(
                        label: 'Personal Info',
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.screenMargin,
                                10,
                                AppSpacing.screenMargin,
                                10),
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
                              color: AppColors.dividerLight),
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
                                0),
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
                                    FilteringTextInputFormatter.digitsOnly
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
                              color: AppColors.dividerLight),
                          _ReadOnlyRow(
                            label: 'Licence Number',
                            value: _original.licenceNumber,
                            note: 'Legal record — cannot be changed',
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
          AppSpacing.screenMargin, topPadding + 12,
          AppSpacing.screenMargin, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: SvgPicture.asset(
              'assets/icons/icon_back.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                  AppColors.textMain, BlendMode.srcIn),
            ),
          ),
          Expanded(
            child: Center(
              child: Text('Edit Profile',
                  style: AppTextStyles.heading1
                      .copyWith(color: AppColors.textMain)),
            ),
          ),
          GestureDetector(
            onTap: isDirty && !isSaving ? onSave : null,
            child: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.secondary),
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
  const _AvatarBlock({
    required this.name,
    required this.profilePhotoBase64,
    required this.loadingPhoto,
    required this.onPickPhoto,
  });

  final String name;
  final String? profilePhotoBase64;
  final bool loadingPhoto;
  final VoidCallback onPickPhoto;

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
          GestureDetector(
            onTap: onPickPhoto,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 41,
                  backgroundColor: AppColors.primary,
                  backgroundImage: profilePhotoBase64 != null
                      ? MemoryImage(base64Decode(profilePhotoBase64!))
                      : null,
                  child: profilePhotoBase64 == null
                      ? Text(
                          initials,
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.w700,
                            fontSize: 26,
                          ),
                        )
                      : null,
                ),
                if (loadingPhoto)
                  const Positioned.fill(
                    child: CircleAvatar(
                      radius: 41,
                      backgroundColor: Colors.black26,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onPickPhoto,
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
              AppSpacing.screenMargin, 14, AppSpacing.screenMargin, 6),
          child: Text(label.toUpperCase(),
              style: AppTextStyles.tag.copyWith(
                color: AppColors.textDisabled,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
              )),
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
            color: AppColors.dividerLight),
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
            horizontal: AppSpacing.screenMargin, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label.toUpperCase(),
                    style: AppTextStyles.tag.copyWith(
                      color: AppColors.textDisabled,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.04,
                    )),
                const SizedBox(width: 6),
                const Icon(Icons.lock_outline,
                    size: 12, color: AppColors.textDisabled),
              ],
            ),
            const SizedBox(height: 4),
            Text(value,
                style: AppTextStyles.subtitle
                    .copyWith(color: AppColors.textMain)),
            const SizedBox(height: 2),
            Text(note,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textDisabled)),
          ],
        ),
      ),
    );
  }
}

