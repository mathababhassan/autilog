import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../shared/widgets/app_text_field.dart';


class ParentEditProfileScreen extends StatefulWidget {
  const ParentEditProfileScreen({
    super.key,
    required this.name,
    required this.gender,
    required this.email,
  });

  final String name;
  final String gender;
  final String email;

  @override
  State<ParentEditProfileScreen> createState() =>
      _ParentEditProfileScreenState();
}

class _ParentEditProfileScreenState extends State<ParentEditProfileScreen> {
  late final TextEditingController _nameCtrl;
  String? _selectedGender;
  
  bool _saving = false;
  String? _profilePhotoBase64;
  bool _loadingPhoto = false;

  bool get _isDirty =>
      _nameCtrl.text.trim() != widget.name ||
      (_selectedGender ?? '') != widget.gender ||
      _profilePhotoBase64 != null;

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
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.name);
    _selectedGender = widget.gender;
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_isDirty) return;
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final Map<String, dynamic> updates = {
        'name': _nameCtrl.text.trim(),
        'gender': _selectedGender ?? '',
      };
      if (_profilePhotoBase64 != null) {
        updates['profilePhotoBase64'] = _profilePhotoBase64;
      }
      await FirebaseFirestore.instance
          .collection('parents')
          .doc(uid)
          .update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      body: Column(
        children: [
          // ── Nav bar ───────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                topPadding + 12,
                AppSpacing.screenMargin,
                12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceDefault,
              border:
                  Border(bottom: BorderSide(color: AppColors.dividerLight)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: AppColors.textMain),
                ),
                Expanded(
                  child: Center(
                    child: Text('Edit Profile',
                        style: AppTextStyles.heading1
                            .copyWith(color: AppColors.textMain)),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Avatar block ───────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(0, 28, 0, 20),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceDefault,
                      border: Border(
                          bottom:
                              BorderSide(color: AppColors.dividerLight)),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickPhoto,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 41,
                                backgroundColor: AppColors.primary,
                                backgroundImage: _profilePhotoBase64 != null
                                    ? MemoryImage(base64Decode(_profilePhotoBase64!))
                                    : null,
                                child: _profilePhotoBase64 == null
                                    ? Text(
                                        _initials(widget.name),
                                        style: const TextStyle(
                                          color: AppColors.textWhite,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 26,
                                        ),
                                      )
                                    : null,
                              ),
                              if (_loadingPhoto)
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
                                    color: AppColors.primary,
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
                        Text(widget.email,
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSubtle)),
                      ],
                    ),
                  ),

                  // ── Personal Info ──────────────────────────────────
                  _EditSection(
                    label: 'Personal Info',
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenMargin,
                            10,
                            AppSpacing.screenMargin,
                            10),
                        child: Column(
                          children: [
                            AppTextField(
                              label: 'Full Name',
                              controller: _nameCtrl,
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                          height: 1,
                          indent: AppSpacing.screenMargin,
                          endIndent: AppSpacing.screenMargin,
                          color: AppColors.dividerLight),
                      // Read-only email
                      _ReadOnlyRow(
                        label: 'Email Address',
                        value: widget.email,
                        note: 'Cannot be changed',
                      ),
                    ],
                  ),

                  // ── Gender ─────────────────────────────────────────
                  _EditSection(
                    label: 'Gender',
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenMargin,
                            12,
                            AppSpacing.screenMargin,
                            12),
                        child: Wrap(
                          spacing: 10,
                          children: [
                            _buildGenderChip('Male', 'male'),
                            _buildGenderChip('Female', 'female'),
                            _buildGenderChip(
                                'Prefer not to say', 'other'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Save button ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenMargin),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            _isDirty && !_saving ? _save : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.pillRadius),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5),
                              )
                            : Text('Save Changes',
                                style: AppTextStyles.subtitle.copyWith(
                                    color: AppColors.textWhite,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChip(String label, String value) {
    final selected =
        _selectedGender == value || _selectedGender == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color:
                selected ? AppColors.textWhite : AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

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
              children: children),
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

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label, required this.value, required this.note});
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
            Row(children: [
              Text(label.toUpperCase(),
                  style: AppTextStyles.tag.copyWith(
                      color: AppColors.textDisabled,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              const Icon(Icons.lock_outline,
                  size: 12, color: AppColors.textDisabled),
            ]),
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
