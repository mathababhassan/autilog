import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

/// Shows a dialog that requires the user to type [confirmText] exactly
/// before the confirm button becomes active. Returns true if confirmed,
/// false or null if dismissed.
Future<bool?> showAppConfirmationDialog({
  required BuildContext context,
  required String title,
  required String description,
  required String confirmText,
  String confirmButtonLabel = 'Confirm',
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AppConfirmationDialog(
      title: title,
      description: description,
      confirmText: confirmText,
      confirmButtonLabel: confirmButtonLabel,
    ),
  );
}

class _AppConfirmationDialog extends StatefulWidget {
  final String title;
  final String description;
  final String confirmText;
  final String confirmButtonLabel;

  const _AppConfirmationDialog({
    required this.title,
    required this.description,
    required this.confirmText,
    required this.confirmButtonLabel,
  });

  @override
  State<_AppConfirmationDialog> createState() => _AppConfirmationDialogState();
}

class _AppConfirmationDialogState extends State<_AppConfirmationDialog> {
  final _controller = TextEditingController();
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final matches = _controller.text == widget.confirmText;
      if (matches != _canConfirm) setState(() => _canConfirm = matches);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      title: Text(widget.title, style: AppTextStyles.heading2),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Type the following to confirm:',
            style: AppTextStyles.caption.copyWith(color: AppColors.textPlaceholder),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '"${widget.confirmText}"',
            style: AppTextStyles.body.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            style: AppTextStyles.body,
            decoration: const InputDecoration(hintText: 'Type here…'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canConfirm ? () => Navigator.of(context).pop(true) : null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: Text(widget.confirmButtonLabel),
        ),
      ],
    );
  }
}
