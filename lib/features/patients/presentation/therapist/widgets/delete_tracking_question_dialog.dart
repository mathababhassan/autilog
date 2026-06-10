import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/theme.dart';

class DeleteTrackingQuestionDialog extends StatefulWidget {
  final String parentId;
  final String childId;
  final String questionId;
  final String questionText;
  final String childName;

  const DeleteTrackingQuestionDialog({
    super.key,
    required this.parentId,
    required this.childId,
    required this.questionId,
    required this.questionText,
    required this.childName,
  });

  @override
  State<DeleteTrackingQuestionDialog> createState() => _DeleteTrackingQuestionDialogState();
}

class _DeleteTrackingQuestionDialogState extends State<DeleteTrackingQuestionDialog> {
  bool _deleting = false;

  Future<void> _delete() async {
    setState(() => _deleting = true);

    try {
      await FirebaseFirestore.instance
          .collection('parents')
          .doc(widget.parentId)
          .collection('children')
          .doc(widget.childId)
          .collection('trackingQuestions')
          .doc(widget.questionId)
          .delete();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting question: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: AppColors.surfaceDefault,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular container with red trash icon
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.error20,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete this question?',
              style: AppTextStyles.subtitle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Question display container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"${widget.questionText}"',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This will permanently remove this question from ${widget.childName}\'s Daily Summary. Historical answers will be kept.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSubtle,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _deleting ? null : _delete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  elevation: 0,
                ),
                child: _deleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'DELETE QUESTION',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Keep question',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSubtle,
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
