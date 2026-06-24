import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/theme.dart';

/// Shows a confirmation dialog before permanently deleting the user's account.
/// Requires the user to type "delete my account" before the button enables.
Future<void> showDeleteAccountDialog({required BuildContext context}) {
  return showDialog(
    context: context,
    builder: (ctx) => const _DeleteAccountDialog(),
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _confirmed = false;
  bool _loading = false;

  static const _requiredPhrase = 'delete my account';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final matches = _controller.text.trim().toLowerCase() == _requiredPhrase;
      if (matches != _confirmed) setState(() => _confirmed = matches);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!_confirmed || _loading) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (_) {
      // Re-authentication may be required — fall back to sign-out.
      await FirebaseAuth.instance.signOut();
    }
    if (mounted) Navigator.pop(context);
    if (mounted) context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Delete Account',
        style: AppTextStyles.subtitle.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.error,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will permanently delete your account and all associated data. '
            'This action cannot be undone.',
            style: AppTextStyles.body.copyWith(color: AppColors.textMain),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Type "delete my account" to confirm:',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSubtle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            autofocus: true,
            style: AppTextStyles.body.copyWith(color: AppColors.textMain),
            decoration: InputDecoration(
              hintText: 'delete my account',
              hintStyle:
                  AppTextStyles.body.copyWith(color: AppColors.textSubtle),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.error, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style:
                AppTextStyles.body.copyWith(color: AppColors.textSubtle),
          ),
        ),
        ElevatedButton(
          onPressed: _confirmed && !_loading ? _delete : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            disabledBackgroundColor: AppColors.error.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textWhite,
                  ),
                )
              : Text(
                  'Delete Account',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textWhite),
                ),
        ),
      ],
    );
  }
}