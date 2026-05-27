import 'package:flutter/material.dart';
import '../../../../shared/widgets/success_animation_widget.dart';
import '../../../../../core/constants/routes.dart';
import 'package:go_router/go_router.dart';

class SummarySavedDialog extends StatelessWidget {
  final String childId; // 👈 receive childId so we can pass it to Log History

  const SummarySavedDialog({
    super.key,
    required this.childId,
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
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: () {
                      // 👇 Pass childId into GoRouter extra
                      context.go(Routes.logHistory, extra: childId);
                    },
                    child: const Text("View Log History"),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: () {
                      // 👇 Use GoRouter for consistency
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
}
