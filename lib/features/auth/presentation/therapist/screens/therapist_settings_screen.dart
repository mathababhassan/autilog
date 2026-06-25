import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../shared/widgets/app_confirmation_dialog.dart';
import '../../../../profile/therapist/data/therapist_repository.dart';
import '../data/therapist_settings_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Therapist Settings (T-36)
//
// Notification preference toggles + account actions. Mirrors the parent
// settings screen's StatefulWidget/load-edit-save pattern, but uses the white
// AppBar + flat grouped-row idiom and persists prefs as a `notificationPrefs`
// map on the therapist's main doc (where the backend reads them).
// ─────────────────────────────────────────────────────────────────────────────

class TherapistSettingsScreen extends StatefulWidget {
  const TherapistSettingsScreen({super.key});

  @override
  State<TherapistSettingsScreen> createState() =>
      _TherapistSettingsScreenState();
}

class _TherapistSettingsScreenState extends State<TherapistSettingsScreen> {
  // ─── State ─────────────────────────────────────────────────────────────────

  TherapistSettingsModel _settings = const TherapistSettingsModel();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  late final String _uid;
  late final DocumentReference<Map<String, dynamic>> _docRef;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _docRef = FirebaseFirestore.instance.collection('therapists').doc(_uid);
    _load();
  }

  // ─── Firestore ─────────────────────────────────────────────────────────────

  Future<void> _load() async {
    if (_uid.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'You need to be signed in to view your settings.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final snap = await _docRef.get();
      final prefs =
          (snap.data()?['notificationPrefs'] as Map<String, dynamic>?) ??
              const <String, dynamic>{};

      if (mounted) {
        setState(() {
          _settings = TherapistSettingsModel.fromMap(prefs);
          _loading = false;
        });
      }
    } on FirebaseException catch (e) {
      // permission-denied → rules not yet deployed; fall back to defaults so
      // the screen is still usable rather than blocking on an error.
      if (e.code == 'permission-denied') {
        if (mounted) {
          setState(() {
            _settings = const TherapistSettingsModel();
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = "We couldn't load your settings. Please try again.";
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = "We couldn't load your settings. Please try again.";
        });
      }
    }
  }

  Future<void> _save() async {
    if (_uid.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await _docRef.set(
        {'notificationPrefs': _settings.toMap()},
        SetOptions(merge: true),
      );
      if (mounted) _showSnack('Settings saved', success: true);
    } catch (_) {
      if (mounted) {
        _showSnack(
          "We couldn't save your settings. Please try again.",
          success: false,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _update(TherapistSettingsModel next) {
    setState(() => _settings = next);
  }

  void _showSnack(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppTextStyles.body.copyWith(color: AppColors.textWhite),
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        ),
        margin: const EdgeInsets.all(AppSpacing.lg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onBack() =>
      context.canPop() ? context.pop() : context.go(Routes.therapistHome);

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.surfaceDefault,
        body: Column(
          children: [
            _Header(onBack: _onBack),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── Notifications ──────────────────────────────────────────
        const _SectionLabel('Notifications'),
        _SettingsRow(
          title: 'Patient requests',
          subtitle: 'New requests to link a patient.',
          value: _settings.patientRequests,
          onChanged: (v) => _update(_settings.copyWith(patientRequests: v)),
        ),
        const _RowDivider(),
        _SettingsRow(
          title: 'Patient activity',
          subtitle: 'New logs and comments from parents.',
          value: _settings.patientActivity,
          onChanged: (v) => _update(_settings.copyWith(patientActivity: v)),
        ),
        const _RowDivider(),
        const _SettingsRow(
          title: 'High-severity alerts',
          subtitle: 'Always on for safety.',
          value: true,
          locked: true,
        ),
        const _RowDivider(),
        _SettingsRow(
          title: 'Session updates',
          subtitle: 'Reminders and parent cancellations.',
          value: _settings.sessionUpdates,
          onChanged: (v) => _update(_settings.copyWith(sessionUpdates: v)),
        ),
        const _RowDivider(),
        _SettingsRow(
          title: 'Weekly AI insights',
          subtitle: "When a patient's weekly summary is ready.",
          value: _settings.weeklyAiInsights,
          onChanged: (v) => _update(_settings.copyWith(weeklyAiInsights: v)),
        ),

        const SizedBox(height: AppSpacing.xl2),

        // ── Account ────────────────────────────────────────────────
        const _SectionLabel('Account'),
        _AccountRow(
          label: 'Change Password',
          color: AppColors.secondary,
          showChevron: true,
          onTap: () => _showChangePasswordDialog(context),
        ),
        const _RowDivider(),
        _AccountRow(
          label: 'Sign Out',
          color: AppColors.error,
          onTap: () => _confirmSignOut(context),
        ),
        const _RowDivider(),
        _AccountRow(
          label: 'Delete Account',
          color: AppColors.error,
          onTap: _confirmDeleteAccount,
        ),

        const SizedBox(height: AppSpacing.xl3),

        // ── Save ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                disabledBackgroundColor: AppColors.primary40,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.textWhite,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Save Settings',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.xl2),
      ],
    );
  }

  // ─── Account dialogs ─────────────────────────────────────────────────────────

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceModal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        ),
        title: Text(
          'Change Password',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textMain),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password (min 8 chars)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTextStyles.body.copyWith(color: AppColors.secondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentPassword = currentPasswordController.text;
              final newPassword = newPasswordController.text;
              if (currentPassword.isEmpty || newPassword.length < 8) return;
              try {
                final user = FirebaseAuth.instance.currentUser!;
                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: currentPassword,
                );
                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newPassword);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  _showSnack('Password updated', success: true);
                }
              } on FirebaseAuthException catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  _showSnack(
                    e.code == 'wrong-password'
                        ? 'Current password is incorrect.'
                        : 'Failed to update password.',
                    success: false,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              ),
            ),
            child: Text(
              'Update',
              style: AppTextStyles.body.copyWith(color: AppColors.textWhite),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
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
    if (confirmed != true || !mounted) return;

    try {
      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      await context.read<TherapistRepository>().deleteProfile(_uid, email);
      if (mounted) context.go(Routes.login);
    } catch (_) {
      if (mounted) {
        _showSnack(
          "We couldn't delete your account. Please try again.",
          success: false,
        );
      }
    }
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
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
            onPressed: () => Navigator.pop(ctx),
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
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) context.go(Routes.login);
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
}

// ─────────────────────────────────────────────────────────────────────────────
// White AppBar header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.surfaceDefault,
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        children: [
          SizedBox(
            height: kToolbarHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SvgPicture.asset(
                          'assets/icons/icon_back.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            AppColors.textMain,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Settings', style: AppTextStyles.heading1),
                ],
              ),
            ),
          ),
          const Divider(
            height: 0.5,
            thickness: 0.5,
            color: AppColors.borderInactive,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Uppercase section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.tag.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textDisabled,
          letterSpacing: 0.96,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Flat notification toggle row (with a locked, always-on variant)
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
    this.locked = false,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textPlaceholder),
                  ),
                ],
              ),
            ),
          ),
          if (locked) ...[
            const Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: AppColors.textDisabled,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Switch.adaptive(
            value: value,
            onChanged: locked ? null : onChanged,
            activeThumbColor: AppColors.textWhite,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.labelInactive,
            inactiveTrackColor: AppColors.borderInactive,
          ),
        ],
      ),
    );

    return locked ? Opacity(opacity: 0.6, child: row) : row;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Flat account action row
// ─────────────────────────────────────────────────────────────────────────────

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.label,
    required this.onTap,
    this.color = AppColors.textMain,
    this.showChevron = false,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: color.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Indented row divider
// ─────────────────────────────────────────────────────────────────────────────

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Divider(height: 1, thickness: 1, color: AppColors.dividerLight),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.textSubtle,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.textMain),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
