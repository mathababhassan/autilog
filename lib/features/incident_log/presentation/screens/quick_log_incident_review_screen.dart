import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../shared/widgets/app_snackbar.dart';

// ─── Constants (mirrors Cloud Function) ──────────────────────────────────────

const _kTriggers = [
  'Routine Change', 'Loud Environment', 'Hunger', 'Fatigue',
  'Crowded Place', 'Sensory Stimulus', 'Transition',
  'Social Demand', 'School Related', 'Unknown', 'Other',
];
const _kBehaviors = [
  'Meltdown', 'Aggression', 'Self-harm', 'Repetitive Behavior',
  'Withdrawal', 'Refusal', 'Other',
];
const _kStrategies = [
  'Redirection', 'Reward', 'Ignore', 'Comfort',
  'Verbal Reassurance', 'Sensory Tool', 'Physical Comfort',
  'Quiet Space', 'Other',
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class QuickLogIncidentReviewScreen extends StatefulWidget {
  const QuickLogIncidentReviewScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.fields,
  });

  final String patientId;
  final String patientName;
  final Map<String, dynamic> fields;

  @override
  State<QuickLogIncidentReviewScreen> createState() =>
      _QuickLogIncidentReviewScreenState();
}

class _QuickLogIncidentReviewScreenState
    extends State<QuickLogIncidentReviewScreen> {
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
      final timeMinutes = (_f['time'] as int?) ?? (now.hour * 60 + now.minute);

      final data = {
        'date': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
        'time': timeMinutes,
        'antecedentDescription': _f['antecedentDescription'] ?? '',
        'antecedentTriggers': List<String>.from(_f['antecedentTriggers'] ?? []),
        'antecedentSeverity': (_f['antecedentSeverity'] as int?) ?? 3,
        'behaviorDescription': _f['behaviorDescription'] ?? '',
        'behaviorTypes': List<String>.from(_f['behaviorTypes'] ?? []),
        'behaviorDuration': (_f['behaviorDuration'] as int?) ?? 0,
        'behaviorSeverity': (_f['behaviorSeverity'] as int?) ?? 3,
        'consequenceDescription': _f['consequenceDescription'] ?? '',
        'strategies': List<String>.from(_f['strategies'] ?? []),
        'didItWork': _f['didItWork'] as bool? ?? false,
        'effectiveness': (_f['effectiveness'] as int?) ?? 3,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      await FirebaseFirestore.instance
          .collection('parents')
          .doc(uid)
          .collection('children')
          .doc(widget.patientId)
          .collection('incidents')
          .add(data);

      if (mounted) {
        AppSnackbar.showSuccess(context, 'Incident logged successfully.');
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
            _InfoBanner(patientName: widget.patientName),
            const SizedBox(height: 20),
            _sectionTitle('Antecedent (What happened before)'),
            const SizedBox(height: 10),
            _EditableTextCard(
              label: 'Description',
              value: _f['antecedentDescription'] ?? '',
              onEdit: (v) => setState(() => _f['antecedentDescription'] = v),
            ),
            const SizedBox(height: 10),
            _ChipsCard(
              label: 'Triggers',
              values: List<String>.from(_f['antecedentTriggers'] ?? []),
              options: _kTriggers,
              onEdit: (v) => setState(() => _f['antecedentTriggers'] = v),
            ),
            const SizedBox(height: 10),
            _SeverityCard(
              label: 'Trigger Severity',
              value: (_f['antecedentSeverity'] as int?) ?? 3,
              onEdit: (v) => setState(() => _f['antecedentSeverity'] = v),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Behavior (What the child did)'),
            const SizedBox(height: 10),
            _EditableTextCard(
              label: 'Description',
              value: _f['behaviorDescription'] ?? '',
              onEdit: (v) => setState(() => _f['behaviorDescription'] = v),
            ),
            const SizedBox(height: 10),
            _ChipsCard(
              label: 'Behavior Types',
              values: List<String>.from(_f['behaviorTypes'] ?? []),
              options: _kBehaviors,
              onEdit: (v) => setState(() => _f['behaviorTypes'] = v),
            ),
            const SizedBox(height: 10),
            _SeverityCard(
              label: 'Behavior Severity',
              value: (_f['behaviorSeverity'] as int?) ?? 3,
              onEdit: (v) => setState(() => _f['behaviorSeverity'] = v),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Consequence (How you responded)'),
            const SizedBox(height: 10),
            _EditableTextCard(
              label: 'Description',
              value: _f['consequenceDescription'] ?? '',
              onEdit: (v) => setState(() => _f['consequenceDescription'] = v),
            ),
            const SizedBox(height: 10),
            _ChipsCard(
              label: 'Strategies Used',
              values: List<String>.from(_f['strategies'] ?? []),
              options: _kStrategies,
              onEdit: (v) => setState(() => _f['strategies'] = v),
            ),
            const SizedBox(height: 10),
            _DidItWorkCard(
              value: _f['didItWork'] as bool? ?? false,
              effectiveness: (_f['effectiveness'] as int?) ?? 3,
              onChanged: (worked, eff) => setState(() {
                _f['didItWork'] = worked;
                _f['effectiveness'] = eff;
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _SaveBar(saving: _saving, onSave: _save),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style:
          AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700));
}

// ─── Info Banner ──────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.patientName});
  final String patientName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondaryOrange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.secondaryOrange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome,
              color: AppColors.secondaryOrange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI extracted the details below for $patientName. Review and correct before saving.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.secondaryOrange, height: 1.4),
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
    return _ReviewCard(
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

class _ChipsCard extends StatelessWidget {
  const _ChipsCard({
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
    return _ReviewCard(
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
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
    );
  }
}

// ─── Severity card ────────────────────────────────────────────────────────────

class _SeverityCard extends StatelessWidget {
  const _SeverityCard(
      {required this.label, required this.value, required this.onEdit});
  final String label;
  final int value;
  final ValueChanged<int> onEdit;

  static const _labels = ['', 'Very Mild', 'Mild', 'Moderate', 'Significant', 'Severe'];
  static const _colors = [
    Colors.transparent,
    Color(0xFF2D9D78),
    Color(0xFF7BC47A),
    Color(0xFFFA8601),
    Color(0xFFE57373),
    Color(0xFFDD3636),
  ];

  @override
  Widget build(BuildContext context) {
    return _ReviewCard(
      label: label,
      onTap: () async {
        final result = await showModalBottomSheet<int>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _SeverityEditSheet(label: label, initial: value),
        );
        if (result != null) onEdit(result);
      },
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (value >= 1 && value <= 5)
                  ? _colors[value].withValues(alpha: 0.15)
                  : AppColors.inputFill,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value >= 1 && value <= 5 ? '$value — ${_labels[value]}' : '$value',
              style: AppTextStyles.caption.copyWith(
                  color: value >= 1 && value <= 5
                      ? _colors[value]
                      : AppColors.textMain,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Did It Work card ─────────────────────────────────────────────────────────

class _DidItWorkCard extends StatelessWidget {
  const _DidItWorkCard(
      {required this.value,
      required this.effectiveness,
      required this.onChanged});
  final bool value;
  final int effectiveness;
  final void Function(bool worked, int eff) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Text('Did it work?',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSubtle,
                      fontWeight: FontWeight.w600)),
              Switch(
                value: value,
                onChanged: (v) => onChanged(v, effectiveness),
                activeColor: AppColors.success,
              ),
            ],
          ),
          if (value) ...[
            const SizedBox(height: 8),
            Text('Effectiveness',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSubtle,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: List.generate(5, (i) {
                final v = i + 1;
                final selected = effectiveness == v;
                return GestureDetector(
                  onTap: () => onChanged(value, v),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? AppColors.success
                          : AppColors.surfaceDefault,
                      border: Border.all(
                          color: selected
                              ? AppColors.success
                              : AppColors.borderInactive),
                    ),
                    child: Center(
                      child: Text('$v',
                          style: AppTextStyles.body.copyWith(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textMain,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Base review card ─────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  const _ReviewCard(
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

// ─── Text edit sheet (P-16 antecedent / consequence) ─────────────────────────

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

// ─── Chips edit sheet (P-17 trigger type / behavior type) ────────────────────

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
                          color: selected
                              ? Colors.white
                              : AppColors.textMain,
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

// ─── Severity edit sheet (P-18) ───────────────────────────────────────────────

class _SeverityEditSheet extends StatefulWidget {
  const _SeverityEditSheet({required this.label, required this.initial});
  final String label;
  final int initial;

  @override
  State<_SeverityEditSheet> createState() => _SeverityEditSheetState();
}

class _SeverityEditSheetState extends State<_SeverityEditSheet> {
  late int _value;

  static const _labels = ['', 'Very Mild', 'Mild', 'Moderate', 'Significant', 'Severe'];
  static const _colors = [
    Colors.transparent,
    Color(0xFF2D9D78),
    Color(0xFF7BC47A),
    Color(0xFFFA8601),
    Color(0xFFE57373),
    Color(0xFFDD3636),
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
                        ? _colors[v]
                        : _colors[v].withValues(alpha: 0.12),
                    border: Border.all(
                        color: _colors[v],
                        width: selected ? 2 : 1),
                  ),
                  child: Center(
                    child: Text('$v',
                        style: AppTextStyles.subtitle.copyWith(
                            color:
                                selected ? Colors.white : _colors[v],
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
                color: _colors[_value], fontWeight: FontWeight.w700),
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

// ─── Save bar ─────────────────────────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.saving, required this.onSave});
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
            backgroundColor: AppColors.secondaryOrange,
            disabledBackgroundColor:
                AppColors.secondaryOrange.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: saving
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Text('Save Incident Log',
                  style: AppTextStyles.subtitle.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
