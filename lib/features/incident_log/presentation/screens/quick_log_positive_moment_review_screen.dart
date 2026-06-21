import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../shared/widgets/app_snackbar.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const _kSettings = [
  'Home', 'School', 'Public Place', 'Social Visit', 'Therapy Session', 'Other',
];
const _kBehaviors = [
  'Social Interaction', 'Communication', 'Self-Regulation',
  'Cooperation', 'New Skill', 'Other',
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class QuickLogPositiveMomentReviewScreen extends StatefulWidget {
  const QuickLogPositiveMomentReviewScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.fields,
  });

  final String patientId;
  final String patientName;
  final Map<String, dynamic> fields;

  @override
  State<QuickLogPositiveMomentReviewScreen> createState() =>
      _QuickLogPositiveMomentReviewScreenState();
}

class _QuickLogPositiveMomentReviewScreenState
    extends State<QuickLogPositiveMomentReviewScreen> {
  late Map<String, dynamic> _f;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _f = Map<String, dynamic>.from(widget.fields);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final now = DateTime.now();
      final timeMinutes =
          (_f['time'] as int?) ?? (now.hour * 60 + now.minute);

      final data = {
        'date': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
        'time': timeMinutes,
        'antecedentDescription': _f['antecedentDescription'] ?? '',
        'setting': _f['setting'] ?? 'Home',
        'behaviorDescription': _f['behaviorDescription'] ?? '',
        'behaviorTypes': List<String>.from(_f['behaviorTypes'] ?? []),
        'positiveBehaviorRating': (_f['positiveBehaviorRating'] as int?) ?? 3,
        'consequenceDescription': _f['consequenceDescription'] ?? '',
        'effectiveness': (_f['effectiveness'] as int?) ?? 3,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      await FirebaseFirestore.instance
          .collection('parents')
          .doc(uid)
          .collection('children')
          .doc(widget.patientId)
          .collection('positiveMoments')
          .add(data);

      if (mounted) {
        AppSnackbar.showSuccess(context, 'Positive moment logged!');
        context.pop();
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Could not save. Please try again.');
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDefault,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDefault,
        elevation: 0,
        leading: const BackButton(color: AppColors.textMain),
        title: Text('Review & Edit',
            style:
                AppTextStyles.heading1.copyWith(color: AppColors.textMain)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PmInfoBanner(patientName: widget.patientName),
            const SizedBox(height: 20),
            _sectionTitle('What led to this moment'),
            const SizedBox(height: 10),
            _EditableTextCard(
              label: 'Description',
              value: _f['antecedentDescription'] ?? '',
              onEdit: (v) => setState(() => _f['antecedentDescription'] = v),
            ),
            const SizedBox(height: 10),
            _SettingCard(
              value: _f['setting'] as String? ?? 'Home',
              onEdit: (v) => setState(() => _f['setting'] = v),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Positive Behavior'),
            const SizedBox(height: 10),
            _EditableTextCard(
              label: 'Description',
              value: _f['behaviorDescription'] ?? '',
              onEdit: (v) => setState(() => _f['behaviorDescription'] = v),
            ),
            const SizedBox(height: 10),
            _PmChipsCard(
              label: 'Behavior Types',
              values: List<String>.from(_f['behaviorTypes'] ?? []),
              options: _kBehaviors,
              onEdit: (v) => setState(() => _f['behaviorTypes'] = v),
            ),
            const SizedBox(height: 10),
            _RatingCard(
              label: 'Behavior Strength',
              value: (_f['positiveBehaviorRating'] as int?) ?? 3,
              onEdit: (v) =>
                  setState(() => _f['positiveBehaviorRating'] = v),
            ),
            const SizedBox(height: 20),
            _sectionTitle('How you reinforced it'),
            const SizedBox(height: 10),
            _EditableTextCard(
              label: 'Description',
              value: _f['consequenceDescription'] ?? '',
              onEdit: (v) =>
                  setState(() => _f['consequenceDescription'] = v),
            ),
            const SizedBox(height: 10),
            _RatingCard(
              label: 'Reinforcement Effectiveness',
              value: (_f['effectiveness'] as int?) ?? 3,
              onEdit: (v) => setState(() => _f['effectiveness'] = v),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _PmSaveBar(saving: _saving, onSave: _save),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style:
          AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700));
}

// ─── Banner ───────────────────────────────────────────────────────────────────

class _PmInfoBanner extends StatelessWidget {
  const _PmInfoBanner({required this.patientName});
  final String patientName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.secondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI extracted the details below for $patientName. Review and correct before saving.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.secondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Setting picker card ──────────────────────────────────────────────────────

class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.value, required this.onEdit});
  final String value;
  final ValueChanged<String> onEdit;

  @override
  Widget build(BuildContext context) {
    return _PmReviewCard(
      label: 'Setting',
      onTap: () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _SettingSheet(current: value),
        );
        if (result != null) onEdit(result);
      },
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(value,
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SettingSheet extends StatelessWidget {
  const _SettingSheet({required this.current});
  final String current;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Edit Setting',
              style: AppTextStyles.heading1
                  .copyWith(color: AppColors.textMain)),
          const SizedBox(height: 14),
          ..._kSettings.map((s) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s,
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.textMain,
                        fontWeight: s == current
                            ? FontWeight.w700
                            : FontWeight.normal)),
                trailing: s == current
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.secondary)
                    : null,
                onTap: () => Navigator.of(context).pop(s),
              )),
        ],
      ),
    );
  }
}

// ─── Rating card ──────────────────────────────────────────────────────────────

class _RatingCard extends StatelessWidget {
  const _RatingCard(
      {required this.label, required this.value, required this.onEdit});
  final String label;
  final int value;
  final ValueChanged<int> onEdit;

  static const _labels = [
    '', 'Very Low', 'Low', 'Moderate', 'High', 'Very High'
  ];

  @override
  Widget build(BuildContext context) {
    return _PmReviewCard(
      label: label,
      onTap: () async {
        final result = await showModalBottomSheet<int>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _RatingSheet(label: label, initial: value),
        );
        if (result != null) onEdit(result);
      },
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value >= 1 && value <= 5
                  ? '$value — ${_labels[value]}'
                  : '$value',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.success, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingSheet extends StatefulWidget {
  const _RatingSheet({required this.label, required this.initial});
  final String label;
  final int initial;

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  late int _value;
  static const _labels = [
    '', 'Very Low', 'Low', 'Moderate', 'High', 'Very High'
  ];

  @override
  void initState() {
    super.initState();
    _value = widget.initial.clamp(1, 5);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Edit ${widget.label}',
              style: AppTextStyles.heading1
                  .copyWith(color: AppColors.textMain)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final v = i + 1;
              final selected = _value == v;
              return GestureDetector(
                onTap: () => setState(() => _value = v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? AppColors.success
                        : AppColors.success.withValues(alpha: 0.12),
                    border: Border.all(
                        color: AppColors.success,
                        width: selected ? 2 : 1),
                  ),
                  child: Center(
                    child: Text('$v',
                        style: AppTextStyles.subtitle.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.success,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            _value >= 1 && _value <= 5 ? _labels[_value] : '',
            style: AppTextStyles.body.copyWith(
                color: AppColors.success, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_value),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Done',
                  style: AppTextStyles.body.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Editable text card ───────────────────────────────────────────────────────

class _EditableTextCard extends StatelessWidget {
  const _EditableTextCard(
      {required this.label, required this.value, required this.onEdit});
  final String label;
  final String value;
  final ValueChanged<String> onEdit;

  @override
  Widget build(BuildContext context) {
    return _PmReviewCard(
      label: label,
      onTap: () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _TextEditSheet(label: label, initial: value),
        );
        if (result != null) onEdit(result);
      },
      child: Text(value.isEmpty ? '—' : value,
          style: AppTextStyles.body.copyWith(
              color: value.isEmpty
                  ? AppColors.textPlaceholder
                  : AppColors.textMain)),
    );
  }
}

// ─── Chips card ───────────────────────────────────────────────────────────────

class _PmChipsCard extends StatelessWidget {
  const _PmChipsCard({
    required this.label,
    required this.values,
    required this.options,
    required this.onEdit,
  });
  final String label;
  final List<String> values;
  final List<String> options;
  final ValueChanged<List<String>> onEdit;

  @override
  Widget build(BuildContext context) {
    return _PmReviewCard(
      label: label,
      onTap: () async {
        final result = await showModalBottomSheet<List<String>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _ChipsEditSheet(
              label: label, selected: values, options: options),
        );
        if (result != null) onEdit(result);
      },
      child: values.isEmpty
          ? Text('—',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textPlaceholder))
          : Wrap(
              spacing: 6,
              runSpacing: 6,
              children: values
                  .map((v) => Chip(
                        label: Text(v,
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600)),
                        backgroundColor:
                            AppColors.secondary.withValues(alpha: 0.12),
                        side: BorderSide.none,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
    );
  }
}

// ─── Base card ────────────────────────────────────────────────────────────────

class _PmReviewCard extends StatelessWidget {
  const _PmReviewCard(
      {required this.label, required this.child, required this.onTap});
  final String label;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSubtle,
                        fontWeight: FontWeight.w600)),
                const Icon(Icons.edit_outlined,
                    size: 14, color: AppColors.textSubtle),
              ],
            ),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }
}

// ─── Shared bottom sheets ─────────────────────────────────────────────────────

class _TextEditSheet extends StatefulWidget {
  const _TextEditSheet({required this.label, required this.initial});
  final String label;
  final String initial;

  @override
  State<_TextEditSheet> createState() => _TextEditSheetState();
}

class _TextEditSheetState extends State<_TextEditSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Edit ${widget.label}',
              style: AppTextStyles.heading1
                  .copyWith(color: AppColors.textMain)),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLines: 4,
            style: AppTextStyles.body.copyWith(color: AppColors.textMain),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.secondary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(_ctrl.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Done',
                  style: AppTextStyles.body.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipsEditSheet extends StatefulWidget {
  const _ChipsEditSheet(
      {required this.label,
      required this.selected,
      required this.options});
  final String label;
  final List<String> selected;
  final List<String> options;

  @override
  State<_ChipsEditSheet> createState() => _ChipsEditSheetState();
}

class _ChipsEditSheetState extends State<_ChipsEditSheet> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Edit ${widget.label}',
              style: AppTextStyles.heading1
                  .copyWith(color: AppColors.textMain)),
          const SizedBox(height: 6),
          Text('Select up to 3',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSubtle)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.options.map((opt) {
              final selected = _selected.contains(opt);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selected.remove(opt);
                    } else if (_selected.length < 3) {
                      _selected.add(opt);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.secondary
                        : AppColors.inputFill,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: selected
                            ? AppColors.secondary
                            : AppColors.borderInactive),
                  ),
                  child: Text(opt,
                      style: AppTextStyles.caption.copyWith(
                          color:
                              selected ? Colors.white : AppColors.textMain,
                          fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(List<String>.from(_selected)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Done',
                  style: AppTextStyles.body.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Save bar ─────────────────────────────────────────────────────────────────

class _PmSaveBar extends StatelessWidget {
  const _PmSaveBar({required this.saving, required this.onSave});
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDefault,
        border: Border(top: BorderSide(color: AppColors.dividerLight)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: saving ? null : onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            disabledBackgroundColor:
                AppColors.secondary.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: saving
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Text('Save Positive Moment',
                  style: AppTextStyles.subtitle.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
