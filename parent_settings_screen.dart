import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../shared/widgets/delete_account_dialog.dart';
import 'parent_settings_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  // ─── State ─────────────────────────────────────────────────────────────────

  ParentSettingsModel _settings = const ParentSettingsModel();
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
    _docRef = FirebaseFirestore.instance
        .collection('parents')
        .doc(_uid)
        .collection('settings')
        .doc('notifications');
    _load();
  }

  // ─── Firestore ─────────────────────────────────────────────────────────────

  Future<void> _load() async {
    if (_uid.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'User not signed in.';
      });
      return;
    }
    try {
      final snap = await _docRef.get();
      final model = snap.exists && snap.data() != null
          ? ParentSettingsModel.fromMap(snap.data()!)
          : const ParentSettingsModel();
      if (mounted) {
        setState(() {
          _settings = model;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load settings.';
        });
      }
    }
  }

  Future<void> _save() async {
    if (_uid.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await _docRef.set(_settings.toMap(), SetOptions(merge: true));
      if (mounted) {
        _showSnack('Settings saved', success: true);
      }
    } catch (_) {
      if (mounted) _showSnack('Failed to save settings', success: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: AppTextStyles.body.copyWith(color: AppColors.textWhite)),
        backgroundColor:
            success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
        margin: const EdgeInsets.all(AppSpacing.lg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _update(ParentSettingsModel next) {
    setState(() => _settings = next);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _settings.reminderTimeHour,
        minute: _settings.reminderTimeMinute,
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.textWhite,
            onSurface: AppColors.textMain,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    _update(_settings.copyWith(
      reminderTimeHour: picked.hour,
      reminderTimeMinute: picked.minute,
    ));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        body: Column(
          children: [
            _Header(
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(Routes.parentProfile),
            ),
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      children: [
        // ── Notifications section ──────────────────────────────────
        _SectionLabel(label: 'Notifications',
            subtitle: 'Choose which alerts you receive.'),
        const SizedBox(height: AppSpacing.sm),

        _SettingsTile(
          icon: Icons.notifications_active_outlined,
          iconColor: AppColors.primary,
          label: 'Session updates',
          subtitle: 'Scheduling changes, reminders, and notes.',
          value: _settings.sessionReminders,
          enabled: _settings.enableNotifications,
          onChanged: (v) => _update(_settings.copyWith(sessionReminders: v)),
        ),
        _SettingsTile(
          icon: Icons.chat_bubble_outline_rounded,
          iconColor: AppColors.secondary,
          label: 'Therapist comments',
          subtitle: 'When your therapist comments on a log.',
          value: _settings.appointmentReminders,
          enabled: _settings.enableNotifications,
          onChanged: (v) =>
              _update(_settings.copyWith(appointmentReminders: v)),
        ),
        _SettingsTile(
          icon: Icons.edit_note_rounded,
          iconColor: AppColors.secondaryOrange,
          label: 'Daily log reminders',
          subtitle: 'A nudge if you haven\'t logged by evening.',
          value: _settings.dailyLogReminders,
          enabled: _settings.enableNotifications,
          onChanged: (v) =>
              _update(_settings.copyWith(dailyLogReminders: v)),
        ),
        _SettingsTile(
          icon: Icons.auto_graph_rounded,
          iconColor: AppColors.accent,
          label: 'Weekly AI Insights',
          subtitle: 'When a new weekly summary is ready.',
          value: _settings.weeklyAiInsights,
          enabled: _settings.enableNotifications,
          onChanged: (v) =>
              _update(_settings.copyWith(weeklyAiInsights: v)),
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── Reminder time ──────────────────────────────────────────
        if (_settings.enableNotifications &&
            (_settings.sessionReminders ||
                _settings.appointmentReminders ||
                _settings.dailyLogReminders)) ...[
          _SectionLabel(
            label: 'Reminder Time',
            subtitle: 'Default time for daily reminders.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _ReminderTimeTile(
            hour: _settings.reminderTimeHour,
            minute: _settings.reminderTimeMinute,
            onTap: _pickTime,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // ── Account section ────────────────────────────────────────
        _SectionLabel(label: 'Account'),
        const SizedBox(height: AppSpacing.sm),

        _AccountTile(
          icon: Icons.lock_outline_rounded,
          label: 'Change Password',
          onTap: () => _showChangePasswordDialog(context),
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        _AccountTile(
          icon: Icons.logout_rounded,
          label: 'Log Out',
          color: AppColors.error,
          onTap: () => _confirmLogout(context),
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        _AccountTile(
          icon: Icons.delete_outline_rounded,
          label: 'Delete Account',
          color: AppColors.error,
          onTap: () => _confirmDeleteAccount(context),
        ),

        const SizedBox(height: AppSpacing.xl3),

        // ── Save button ────────────────────────────────────────────
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
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius)),
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
        SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
      ],
    );
  }

  // ─── Dialogs ───────────────────────────────────────────────────────────────

  void _showChangePasswordDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Change Password',
            style:
                AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'New Password (min 8 chars)',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSubtle)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length >= 8) {
                await FirebaseAuth.instance.currentUser
                    ?.updatePassword(controller.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  _showSnack('Password updated', success: true);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Update',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out',
            style:
                AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700)),
        content:
            Text('Are you sure you want to log out?', style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSubtle)),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) context.go(Routes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Log Out',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDeleteAccountDialog(context: context);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Orange gradient header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFA8601), Color(0xFFFB9E34)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        topPadding + AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl2,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/icons/icon_back.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  AppColors.textWhite,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Settings',
            style: AppTextStyles.heading1.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.subtitle});

  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.w700, color: AppColors.textMain),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSubtle),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toggle row tile (notification switches)
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xs + 2),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDefault,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: enabled ? AppColors.textMain : AppColors.textSubtle,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSubtle, height: 1.4),
          ),
          trailing: Switch.adaptive(
            value: value && enabled,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: AppColors.textWhite,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.labelInactive,
            inactiveTrackColor: AppColors.borderInactive,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reminder time row
// ─────────────────────────────────────────────────────────────────────────────

class _ReminderTimeTile extends StatelessWidget {
  const _ReminderTimeTile({
    required this.hour,
    required this.minute,
    required this.onTap,
  });

  final int hour;
  final int minute;
  final VoidCallback onTap;

  String _format() {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceDefault,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.access_time_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Reminder Time',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _format(),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit_outlined,
                        color: AppColors.primary, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account action tile
// ─────────────────────────────────────────────────────────────────────────────

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textMain,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceDefault,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
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
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.textSubtle, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text(message,
                style: AppTextStyles.body.copyWith(color: AppColors.textMain),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            TextButton(
              onPressed: onRetry,
              child: Text('Retry',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
