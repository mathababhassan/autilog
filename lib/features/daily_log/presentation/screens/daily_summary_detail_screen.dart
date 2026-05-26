import 'package:flutter/material.dart';

class SleepDetailsSheet extends StatefulWidget {
  final TimeOfDay? initialBedtime;
  final TimeOfDay? initialWakeTime;
  // Returns TimeOfDay — screen converts to DateTime on submit
  final void Function(TimeOfDay? bedtime, TimeOfDay? wakeTime) onSave;

  const SleepDetailsSheet({
    super.key,
    this.initialBedtime,
    this.initialWakeTime,
    required this.onSave,
  });

  @override
  State<SleepDetailsSheet> createState() => _SleepDetailsSheetState();
}

class _SleepDetailsSheetState extends State<SleepDetailsSheet> {
  TimeOfDay? _bedtime;
  TimeOfDay? _wakeTime;

  @override
  void initState() {
    super.initState();
    _bedtime = widget.initialBedtime;
    _wakeTime = widget.initialWakeTime;
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickBedtime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _bedtime ?? const TimeOfDay(hour: 21, minute: 0),
      helpText: 'Select Bedtime',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFFFF8A00)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _bedtime = picked);
  }

  Future<void> _pickWakeTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime ?? const TimeOfDay(hour: 7, minute: 0),
      helpText: 'Select Wake Time',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFFFF8A00)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _wakeTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Sleep Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 24),

          _TimePickerRow(
            label: 'Bedtime',
            value: _bedtime != null ? _formatTime(_bedtime!) : null,
            onTap: _pickBedtime,
          ),
          const SizedBox(height: 16),

          _TimePickerRow(
            label: 'Wake Time',
            value: _wakeTime != null ? _formatTime(_wakeTime!) : null,
            onTap: _pickWakeTime,
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => widget.onSave(_bedtime, _wakeTime),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF8A00),
                side: const BorderSide(color: Color(0xFFFF8A00)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _TimePickerRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: value != null
                  ? const Color(0xFFFFF3E0)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value != null
                    ? const Color(0xFFFF8A00)
                    : const Color(0xFFE0E0E0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? 'Tap to select',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: value != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: value != null
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFFBBBBBB),
                    ),
                  ),
                ),
                Icon(
                  Icons.access_time_rounded,
                  size: 20,
                  color: value != null
                      ? const Color(0xFFFF8A00)
                      : const Color(0xFFBBBBBB),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}