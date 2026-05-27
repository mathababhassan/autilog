import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';

class MealDetailsSheet extends StatefulWidget {
  final bool breakfastEaten;
  final bool lunchEaten;
  final bool dinnerEaten;
  final String? initialBreakfastDetails;
  final String? initialLunchDetails;
  final String? initialDinnerDetails;
  final Function(String?, String?, String?) onSave;

  const MealDetailsSheet({
    super.key,
    required this.breakfastEaten,
    required this.lunchEaten,
    required this.dinnerEaten,
    this.initialBreakfastDetails,
    this.initialLunchDetails,
    this.initialDinnerDetails,
    required this.onSave,
  });

  @override
  State<MealDetailsSheet> createState() => _MealDetailsSheetState();
}

class _MealDetailsSheetState extends State<MealDetailsSheet> {
  late TextEditingController _breakfastController;
  late TextEditingController _lunchController;
  late TextEditingController _dinnerController;

  @override
  void initState() {
    super.initState();
    _breakfastController = TextEditingController(text: widget.initialBreakfastDetails);
    _lunchController = TextEditingController(text: widget.initialLunchDetails);
    _dinnerController = TextEditingController(text: widget.initialDinnerDetails);
  }

  @override
  void dispose() {
    _breakfastController.dispose();
    _lunchController.dispose();
    _dinnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Meal Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (widget.breakfastEaten) ...[
            const Text(
              'Breakfast',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _breakfastController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What did they eat? Any notes?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (widget.lunchEaten) ...[
            const Text(
              'Lunch',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lunchController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What did they eat? Any notes?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (widget.dinnerEaten) ...[
            const Text(
              'Dinner',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dinnerController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What did they eat? Any notes?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSave(
                      _breakfastController.text.trim().isEmpty ? null : _breakfastController.text.trim(),
                      _lunchController.text.trim().isEmpty ? null : _lunchController.text.trim(),
                      _dinnerController.text.trim().isEmpty ? null : _dinnerController.text.trim(),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}