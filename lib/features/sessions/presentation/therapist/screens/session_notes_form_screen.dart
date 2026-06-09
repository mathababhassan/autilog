import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../shared/models/session_model.dart';
import '../../../../../features/sessions/data/session_repository.dart';

class SessionNotesFormScreen extends StatefulWidget {
  const SessionNotesFormScreen({super.key, required this.session});
  final SessionModel session;

  @override
  State<SessionNotesFormScreen> createState() => _SessionNotesFormScreenState();
}

class _SessionNotesFormScreenState extends State<SessionNotesFormScreen> {
  final _privateNotesCtrl = TextEditingController();
  final _parentNotesCtrl = TextEditingController();
  final _repo = SessionRepository();

  String? _selectedProgress;
  bool _saving = false;

  @override
  void dispose() {
    _privateNotesCtrl.dispose();
    _parentNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedProgress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a progress status')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _repo.saveSessionNotes(
        sessionId: widget.session.id,
        progress: _selectedProgress,
        privateNotes: _privateNotesCtrl.text.trim().isEmpty
            ? null
            : _privateNotesCtrl.text.trim(),
        parentNotes: _parentNotesCtrl.text.trim().isEmpty
            ? null
            : _parentNotesCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes saved successfully')),
        );
        Navigator.of(context).pop(true);
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
    final session = widget.session;
    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDefault,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textMain, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Session Notes',
          style: AppTextStyles.subtitle
              .copyWith(fontWeight: FontWeight.w700, color: AppColors.textMain),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SessionInfoCard(session: session),
            const SizedBox(height: 24),
            _sectionLabel('Progress'),
            const SizedBox(height: 10),
            _ProgressSelector(
              selected: _selectedProgress,
              onChanged: (v) => setState(() => _selectedProgress = v),
            ),
            const SizedBox(height: 24),
            _sectionLabel('Private Notes'),
            const SizedBox(height: 6),
            Text(
              'Only visible to you — not shared with the parent',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
            ),
            const SizedBox(height: 10),
            _NotesField(
              controller: _privateNotesCtrl,
              hint: 'Add your private session notes here...',
            ),
            const SizedBox(height: 24),
            _sectionLabel('Notes for Parent'),
            const SizedBox(height: 6),
            Text(
              'Optional — will be visible to the parent in their app',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
            ),
            const SizedBox(height: 10),
            _NotesField(
              controller: _parentNotesCtrl,
              hint: 'Add notes to share with the parent...',
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'Save Notes',
                        style: AppTextStyles.subtitle
                            .copyWith(color: AppColors.textWhite),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: AppTextStyles.subtitle.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
      );
}

// ─── Session Info Card ────────────────────────────────────────────────────────

class _SessionInfoCard extends StatelessWidget {
  const _SessionInfoCard({required this.session});
  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final initials = session.childName.trim().split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase())
        .take(2)
        .join();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary20,
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.childName,
                  style: AppTextStyles.subtitle.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.textMain),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.formattedDateShort}  ·  ${session.formattedTimeRange}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSubtle),
                ),
                const SizedBox(height: 4),
                Text(
                  session.mode,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSubtle),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Completed',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Progress Selector ────────────────────────────────────────────────────────

class _ProgressSelector extends StatelessWidget {
  const _ProgressSelector({required this.selected, required this.onChanged});
  final String? selected;
  final ValueChanged<String?> onChanged;

  static const _options = [
    _ProgressOption(
      value: 'improving',
      label: 'Improving',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF2D9D78),
      bgColor: Color(0xFFE6F5F0),
    ),
    _ProgressOption(
      value: 'stable',
      label: 'Stable',
      icon: Icons.trending_flat_rounded,
      color: Color(0xFFFA8601),
      bgColor: Color(0xFFFEE7CC),
    ),
    _ProgressOption(
      value: 'needs_attention',
      label: 'Needs Attention',
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFDD3636),
      bgColor: Color(0xFFFBD0CE),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _ProgressChip(
            option: opt,
            isSelected: selected == opt.value,
            onTap: () => onChanged(selected == opt.value ? null : opt.value),
          ),
        ),
      )).toList(),
    );
  }
}

class _ProgressOption {
  const _ProgressOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
}

class _ProgressChip extends StatelessWidget {
  const _ProgressChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });
  final _ProgressOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? option.bgColor : AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? option.color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(option.icon,
                color: isSelected ? option.color : AppColors.textSubtle,
                size: 22),
            const SizedBox(height: 6),
            Text(
              option.label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? option.color : AppColors.textSubtle,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notes Field ──────────────────────────────────────────────────────────────

class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 5,
      maxLength: 1000,
      style: AppTextStyles.body.copyWith(color: AppColors.textMain),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSubtle),
        filled: true,
        fillColor: AppColors.inputFill,
        counterStyle:
            AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
