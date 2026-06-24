import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/theme.dart';
import '../../core/services/pdf_report_service.dart';
import '../../shared/models/incident_model.dart';
import '../../shared/models/positive_moment_model.dart';
import 'app_snackbar.dart';

enum _Preset { last7, last30, thisMonth, custom }

void showExportPdfSheet(
  BuildContext context, {
  required String childId,
  required String childName,
  required String parentId,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => ExportPdfSheet(
      childId: childId,
      childName: childName,
      parentId: parentId,
    ),
  );
}

class ExportPdfSheet extends StatefulWidget {
  final String childId;
  final String childName;
  final String parentId;

  const ExportPdfSheet({
    super.key,
    required this.childId,
    required this.childName,
    required this.parentId,
  });

  @override
  State<ExportPdfSheet> createState() => _ExportPdfSheetState();
}

class _ExportPdfSheetState extends State<ExportPdfSheet> {
  _Preset _selected = _Preset.last30;
  DateTime? _customFrom;
  DateTime? _customTo;
  bool _generating = false;

  final _dateFmt = DateFormat('d MMM yyyy');

  DateTime get _from {
    final now = DateTime.now();
    return switch (_selected) {
      _Preset.last7 => now.subtract(const Duration(days: 7)),
      _Preset.last30 => now.subtract(const Duration(days: 30)),
      _Preset.thisMonth => DateTime(now.year, now.month, 1),
      _Preset.custom => _customFrom ?? now.subtract(const Duration(days: 30)),
    };
  }

  DateTime get _to {
    return _selected == _Preset.custom
        ? (_customTo ?? DateTime.now())
        : DateTime.now();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_customFrom ?? now.subtract(const Duration(days: 30))) : (_customTo ?? now),
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _customFrom = picked;
        if (_customTo != null && _customTo!.isBefore(picked)) _customTo = picked;
      } else {
        _customTo = picked;
      }
    });
  }

  Future<void> _generate() async {
    if (_selected == _Preset.custom && (_customFrom == null || _customTo == null)) {
      AppSnackbar.showError(context, 'Please select both From and To dates.');
      return;
    }

    setState(() => _generating = true);

    try {
      final fs = FirebaseFirestore.instance;
      final fromTs = Timestamp.fromDate(_from);
      final toTs = Timestamp.fromDate(_to.add(const Duration(days: 1)));

      final incidentsSnap = await fs
          .collection('parents')
          .doc(widget.parentId)
          .collection('children')
          .doc(widget.childId)
          .collection('incidents')
          .where('date', isGreaterThanOrEqualTo: fromTs)
          .where('date', isLessThan: toTs)
          .get();

      final momentsSnap = await fs
          .collection('parents')
          .doc(widget.parentId)
          .collection('children')
          .doc(widget.childId)
          .collection('positiveMoments')
          .where('date', isGreaterThanOrEqualTo: fromTs)
          .where('date', isLessThan: toTs)
          .get();

      final incidents = incidentsSnap.docs
          .map((d) => IncidentModel.fromMap(d.data(), d.id))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final moments = momentsSnap.docs
          .map((d) => PositiveMomentModel.fromMap(d.data(), d.id))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      if (!mounted) return;
      Navigator.pop(context);

      await PdfReportService.exportReport(
        childName: widget.childName,
        from: _from,
        to: _to,
        incidents: incidents,
        positiveMoments: moments,
      );
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Could not generate report. Please try again.');
        setState(() => _generating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.screenMargin,
        right: AppSpacing.screenMargin,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl3,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceModal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.sheetRadius)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl2),
          Text('Export Report', style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.childName,
            style: AppTextStyles.caption.copyWith(color: AppColors.textDisabled),
          ),
          const SizedBox(height: AppSpacing.xl2),
          // Preset chips
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _PresetChip(label: 'Last 7 days', selected: _selected == _Preset.last7, onTap: () => setState(() => _selected = _Preset.last7)),
              _PresetChip(label: 'Last 30 days', selected: _selected == _Preset.last30, onTap: () => setState(() => _selected = _Preset.last30)),
              _PresetChip(label: 'This month', selected: _selected == _Preset.thisMonth, onTap: () => setState(() => _selected = _Preset.thisMonth)),
              _PresetChip(label: 'Custom range', selected: _selected == _Preset.custom, onTap: () => setState(() => _selected = _Preset.custom)),
            ],
          ),
          // Custom date pickers
          if (_selected == _Preset.custom) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'From',
                    value: _customFrom != null ? _dateFmt.format(_customFrom!) : 'Select date',
                    onTap: () => _pickDate(isFrom: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _DateButton(
                    label: 'To',
                    value: _customTo != null ? _dateFmt.format(_customTo!) : 'Select date',
                    onTap: () => _pickDate(isFrom: false),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          // Range preview
          if (_selected != _Preset.custom || (_customFrom != null && _customTo != null))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textPlaceholder),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${_dateFmt.format(_from)} – ${_dateFmt.format(_to)}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textPlaceholder),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xl2),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_outlined, size: 18, color: Colors.white),
              label: Text(
                _generating ? 'Generating...' : 'Generate PDF',
                style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.inputFill,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.pillRadius)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.inputFill,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          border: Border.all(color: selected ? AppColors.primary : AppColors.borderInactive),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? Colors.white : AppColors.textMain,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateButton({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderInactive),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textPlaceholder)),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
