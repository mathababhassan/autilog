import 'package:flutter/material.dart';

class SleepDetailsSheet extends StatefulWidget {
  final TimeOfDay? initialBedtime;
  final TimeOfDay? initialWakeTime;
  final void Function(TimeOfDay bedtime, TimeOfDay wakeTime) onSave;

  const SleepDetailsSheet({
    super.key,
    required this.initialBedtime,
    required this.initialWakeTime,
    required this.onSave,
  });

  @override
  State<SleepDetailsSheet> createState() => _SleepDetailsSheetState();
}

class _SleepDetailsSheetState extends State<SleepDetailsSheet> {
  late TimeOfDay _bedtime;
  late TimeOfDay _wakeTime;

  @override
  void initState() {
    super.initState();
    // Use provided initial values or sensible defaults
    _bedtime = widget.initialBedtime ?? const TimeOfDay(hour: 22, minute: 0);
    _wakeTime = widget.initialWakeTime ?? const TimeOfDay(hour: 7, minute: 0);
  }

  Future<void> _pickTime(BuildContext context, bool isBedtime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isBedtime ? _bedtime : _wakeTime,
    );
    if (picked != null) {
      setState(() {
        if (isBedtime) {
          _bedtime = picked;
        } else {
          _wakeTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Sleep Details",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Bedtime row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Bedtime: ${_bedtime.format(context)}"),
              TextButton(
                onPressed: () => _pickTime(context, true),
                child: const Text("Change"),
              ),
            ],
          ),

          // Wake time row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Wake Time: ${_wakeTime.format(context)}"),
              TextButton(
                onPressed: () => _pickTime(context, false),
                child: const Text("Change"),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Save button
          ElevatedButton(
            onPressed: () {
              widget.onSave(_bedtime, _wakeTime);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A00), // orange accent
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
