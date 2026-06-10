import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/theme.dart';

class EditTrackingQuestionSheet extends StatefulWidget {
  final String parentId;
  final String childId;
  final String questionId;
  final String currentText;
  final String currentAnswerType;
  final String currentStatus;

  const EditTrackingQuestionSheet({
    super.key,
    required this.parentId,
    required this.childId,
    required this.questionId,
    required this.currentText,
    required this.currentAnswerType,
    required this.currentStatus,
  });

  @override
  State<EditTrackingQuestionSheet> createState() => _EditTrackingQuestionSheetState();
}

class _EditTrackingQuestionSheetState extends State<EditTrackingQuestionSheet> {
  late final TextEditingController _textController;
  final _formKey = GlobalKey<FormState>();
  late String _selectedAnswerType;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.currentText);
    _selectedAnswerType = widget.currentAnswerType;
    _isActive = widget.currentStatus == 'active';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final text = _textController.text.trim();
    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('parents')
          .doc(widget.parentId)
          .collection('children')
          .doc(widget.childId)
          .collection('trackingQuestions')
          .doc(widget.questionId)
          .update({
        'questionText': text,
        'answerType': _selectedAnswerType,
        'status': _isActive ? 'active' : 'inactive',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating question: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildOption({
    required String label,
    required String value,
    String? subtitle,
  }) {
    final isSelected = _selectedAnswerType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAnswerType = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom radio button matching the premium design
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.iconDefault,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: AppColors.textMain,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSubtle,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderInactive,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Edit Tracking Question',
                style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              Text(
                'Question Text',
                style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _textController,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'e.g. Did Adam have screen time before bed?',
                  hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSubtle),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  errorStyle: const TextStyle(height: 0.8),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the question text';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Answer Type',
                style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderInactive),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildOption(
                      label: 'Yes or No',
                      value: 'yes_no',
                    ),
                    const Divider(height: 1, color: AppColors.borderInactive),
                    _buildOption(
                      label: 'Number',
                      subtitle: 'with unit (hours / minutes / times per day)',
                      value: 'number',
                    ),
                    const Divider(height: 1, color: AppColors.borderInactive),
                    _buildOption(
                      label: 'Text input',
                      value: 'text',
                    ),
                    const Divider(height: 1, color: AppColors.borderInactive),
                    _buildOption(
                      label: 'Rating 1–5',
                      value: 'rating',
                    ),
                    const Divider(height: 1, color: AppColors.borderInactive),
                    _buildOption(
                      label: 'Time picker',
                      value: 'time',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Status Toggle
              Row(
                children: [
                  Text(
                    'Status: ',
                    style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: _isActive ? AppColors.success : AppColors.textSubtle,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isActive ? 'Active' : 'Inactive',
                    style: AppTextStyles.subtitle.copyWith(
                      color: _isActive ? AppColors.success : AppColors.textSubtle,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _isActive,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                    inactiveThumbColor: AppColors.iconDefault,
                    inactiveTrackColor: AppColors.inputFill,
                    onChanged: (val) {
                      setState(() {
                        _isActive = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'SAVE CHANGES',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSubtle),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
