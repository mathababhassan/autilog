part of 'daily_summary_bloc.dart';

abstract class DailySummaryState extends Equatable {
  const DailySummaryState();
  @override
  List<Object?> get props => [];
}

class DailySummaryInitial extends DailySummaryState {
  const DailySummaryInitial();
}

class DailySummarySaving extends DailySummaryState {
  const DailySummarySaving();
}

class DailySummarySaved extends DailySummaryState {
  const DailySummarySaved();
}

class DailySummaryLoading extends DailySummaryState {
  const DailySummaryLoading();
}

class DailySummariesLoaded extends DailySummaryState {
  final List<DailySummaryModel> summaries;
  const DailySummariesLoaded(this.summaries);

  @override
  List<Object?> get props => [summaries];
}

class DailySummaryError extends DailySummaryState {
  final String message;
  const DailySummaryError(this.message);

  @override
  List<Object?> get props => [message];
}
class DailySummaryDeleting extends DailySummaryState {
  const DailySummaryDeleting();
}

class DailySummaryDeleted extends DailySummaryState {
  const DailySummaryDeleted();
}

