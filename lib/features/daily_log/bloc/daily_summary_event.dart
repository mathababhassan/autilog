part of 'daily_summary_bloc.dart';

abstract class DailySummaryEvent extends Equatable {
  const DailySummaryEvent();
  @override
  List<Object?> get props => [];
}

class SaveDailySummaryEvent extends DailySummaryEvent {
  final DailySummaryModel summary;
  const SaveDailySummaryEvent(this.summary);
}

class LoadDailySummariesEvent extends DailySummaryEvent {
  final String childId;
  const LoadDailySummariesEvent(this.childId);
}
class DeleteDailySummaryEvent extends DailySummaryEvent {
  final String childId;
  final DateTime date;
  const DeleteDailySummaryEvent({required this.childId, required this.date});
}
class UpdateDailySummaryEvent extends DailySummaryEvent {
  final DailySummaryModel summary;
  const UpdateDailySummaryEvent(this.summary);

  @override
  List<Object?> get props => [summary];
}

