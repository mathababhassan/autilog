import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../daily_log/bloc/daily_summary_bloc.dart';
import '../../../../shared/models/daily_summary_model.dart';
import '../../../../core/constants/routes.dart';
import 'package:go_router/go_router.dart';

class LogHistoryScreen extends StatelessWidget {
  final String childId;
  const LogHistoryScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    // 👇 Trigger the bloc to load summaries as soon as the screen builds
    context.read<DailySummaryBloc>().add(LoadDailySummariesEvent(childId));

    return Scaffold(
      appBar: AppBar(title: const Text("Log History")),
      body: BlocBuilder<DailySummaryBloc, DailySummaryState>(
        builder: (context, state) {
          if (state is DailySummaryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is DailySummariesLoaded) {
            if (state.summaries.isEmpty) {
              return const Center(child: Text("No logs found."));
            }
            return ListView.builder(
              itemCount: state.summaries.length,
              itemBuilder: (context, index) {
                final summary = state.summaries[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      "Date: ${summary.date.toLocal().toString().split(' ')[0]}",
                    ),
                    subtitle: Text(
                      "Sleep: ${summary.sleepRating.name}, Mood: ${summary.moodRating.name}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        context.go(
                          Routes.dailySummary,
                          extra: {
                            'parentId': summary.createdBy ?? '',
                            'childId': summary.childId,
                            'childName': '', // add if available
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            );
          } else if (state is DailySummaryError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text("Loading logs..."));
        },
      ),
    );
  }
}
