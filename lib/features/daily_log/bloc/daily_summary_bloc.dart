import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/daily_summary_model.dart';
import '../data/daily_summary_repository.dart';

part 'daily_summary_event.dart';
part 'daily_summary_state.dart';

class DailySummaryBloc extends Bloc<DailySummaryEvent, DailySummaryState> {
  final DailySummaryRepository _repository;

  DailySummaryBloc({required DailySummaryRepository repository})
      : _repository = repository,
        super(const DailySummaryInitial()) {
    on<SaveDailySummaryEvent>(_onSaveSummary);
    on<LoadDailySummariesEvent>(_onLoadSummaries);
    on<DeleteDailySummaryEvent>(_onDeleteSummary); // <-- add this
  }

  Future<void> _onSaveSummary(
    SaveDailySummaryEvent event,
    Emitter<DailySummaryState> emit,
  ) async {
    emit(const DailySummarySaving());
    try {
      await _repository.saveSummary(event.summary);
      emit(const DailySummarySaved());
    } catch (e) {
      emit(DailySummaryError("Failed to save summary: $e"));
    }
  }

  Future<void> _onLoadSummaries(
    LoadDailySummariesEvent event,
    Emitter<DailySummaryState> emit,
  ) async {
    emit(const DailySummaryLoading());
    try {
      final summaries = await _repository.getSummaries(event.childId);
      emit(DailySummariesLoaded(summaries));
    } catch (e) {
      emit(DailySummaryError("Failed to load summaries: $e"));
    }
  }

  Future<void> _onDeleteSummary(
    DeleteDailySummaryEvent event,
    Emitter<DailySummaryState> emit,
  ) async {
    emit(const DailySummaryDeleting());
    try {
      await _repository.deleteSummary(
        childId: event.childId,
        date: event.date,
      );
      emit(const DailySummaryDeleted());
    } catch (e) {
      emit(DailySummaryError("Failed to delete summary: $e"));
    }
  }
}
