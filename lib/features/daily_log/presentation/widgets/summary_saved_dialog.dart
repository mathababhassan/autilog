import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/success_animation_widget.dart';
import '../../../../../core/constants/routes.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/theme.dart';

class SummarySavedDialog extends StatelessWidget {
  final String childId;
  final String childName;
  final DateTime date;

  const SummarySavedDialog({
    super.key,
    required this.childId,
    required this.childName,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SuccessAnimationWidget(),
            const SizedBox(height: 16),
            const Text(
              "Daily Summary Saved!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "$childName's summary for ${_formatDate(date)} has been saved.",
              style: const TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go(Routes.logHistory, extra: childId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                    ),
                    child: const Text("View Log History"),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go(Routes.parentHome);
                    },
                    child: const Text("Back to Home"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM').format(date);
  }
}