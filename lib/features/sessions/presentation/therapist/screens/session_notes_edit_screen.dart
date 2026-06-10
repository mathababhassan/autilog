import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../shared/models/session_model.dart';
import '../../../../../features/sessions/data/session_repository.dart';

class SessionNotesEditScreen extends StatefulWidget {
  const SessionNotesEditScreen({super.key, required this.session});
  final SessionModel session;

  @override
  State<SessionNotesEditScreen> createState() => _SessionNotesEditScreenState();
}

class _SessionNotesEditScreenState extends State<SessionNotesEditScreen> {
  late final TextEditingController _parentNotesCtrl;
  late final TextEditingController _privateNotesCtrl;
  final _repo = SessionRepository();

  String? _selectedProgress;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _parentNotesCtrl = TextEditingController(text: widget.session.notes ?? '');
    _privateNotesCtrl =
        TextEditingController(text: widget.session.privateNotes ?? '');
    _selectedProgress = widget.session.progress;
  }

  @override
  void dispose() {
    _parentNotesCtrl.dispose();
    _privateNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
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
          const SnackBar(content: Text('Notes updated successfully')),
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
          'Edit Session Notes',
          style: AppTextStyles.subtitle.copyWith(
              fontWeight: FontWeight.w700, color: AppColors.textMain),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EditInfoCard(session: session),
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
            _buildTextField(
                controller: _privateNotesCtrl,
                hint: 'Your private notes...'),
            const SizedBox(height: 24),

            _sectionLabel('Notes for Parent'),
            const SizedBox(height: 6),
            Text(
              'Visible to the parent in their app',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
            ),
            const SizedBox(height: 10),
            _buildTextField(
                controller: _parentNotesCtrl,
                hint: 'Notes for the parent...'),

            if (session.notesLastEditedAt != null) ...[
              const SizedBox(height: 10),
              Text(
                'Last edited: ${_formatDateTime(session.notesLastEditedAt!)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSubtle,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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
                        'Save Changes',
                        style: AppTextStyles.subtitle
                            .copyWith(color: AppColors.textWhite),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSubtle,
                    fontWeight: FontWeight.w600,
                  ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, value, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: controller,
              maxLines: 5,
              maxLength: 1000,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
              style: AppTextStyles.body.copyWith(color: AppColors.textMain),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    AppTextStyles.body.copyWith(color: AppColors.textSubtle),
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${value.text.length} / 1000',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSubtle),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  $h:$m $period';
  }
}

// ─── Session Info Card ────────────────────────────────────────────────────────

class _EditInfoCard extends StatelessWidget {
  const _EditInfoCard({required this.session});
  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
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
                  '${session.formattedDateShort}  ·  ${session.formattedTimeRange}  ·  ${session.mode}  ·  ${session.durationMinutes} min',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSubtle),
                ),
              ],
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
