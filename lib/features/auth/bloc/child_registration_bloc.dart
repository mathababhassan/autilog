import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'child_registration_event.dart';
import 'child_registration_state.dart';
import '../../../features/auth/data/auth_repository.dart';

class ChildRegistrationBloc
    extends Bloc<ChildRegistrationEvent, ChildRegistrationState> {
  final AuthRepository authRepository;

  ChildRegistrationBloc({required this.authRepository})
      : super(const ChildRegistrationState()) {
    on<ChildNameChanged>(_onNameChanged);
    on<ChildAgeChanged>(_onAgeChanged);
    on<ChildDobChanged>(_onDobChanged);
    on<ChildSeverityChanged>(_onSeverityChanged);
    on<ChildGenderChanged>(_onGenderChanged);
    on<ChildTherapistEmailChanged>(_onTherapistEmailChanged);
    on<ChildRegistrationSubmitted>(_onSubmitted);
  }

  void _onNameChanged(
      ChildNameChanged event, Emitter<ChildRegistrationState> emit) {
    emit(state.copyWith(name: event.name, clearNameError: true));
  }

  void _onAgeChanged(
      ChildAgeChanged event, Emitter<ChildRegistrationState> emit) {
    emit(state.copyWith(age: event.age, clearAgeError: true));
  }

  void _onDobChanged(
      ChildDobChanged event, Emitter<ChildRegistrationState> emit) {
    emit(state.copyWith(dob: event.dob, clearAgeError: true));
  }

  void _onSeverityChanged(
      ChildSeverityChanged event, Emitter<ChildRegistrationState> emit) {
    emit(state.copyWith(
        asdSeverity: event.severity, clearAsdSeverityError: true));
  }

  void _onGenderChanged(
      ChildGenderChanged event, Emitter<ChildRegistrationState> emit) {
    emit(state.copyWith(gender: event.gender));
  }

  void _onTherapistEmailChanged(ChildTherapistEmailChanged event,
      Emitter<ChildRegistrationState> emit) {
    emit(state.copyWith(therapistEmail: event.email));
  }

  Future<void> _onSubmitted(
    ChildRegistrationSubmitted event,
    Emitter<ChildRegistrationState> emit,
  ) async {
    // Validate
    final nameError =
        state.name.trim().isEmpty ? 'Name cannot be empty' : null;

    final ageInt = int.tryParse(state.age.trim());
    final ageError = state.dob == null
        ? 'Please select a date of birth'
        : (ageInt == null || ageInt <= 0 || ageInt > 18)
            ? 'Age must be between 1 and 18'
            : null;

    final asdSeverityError =
        state.asdSeverity.isEmpty ? 'Please select a diagnosis type' : null;

    if (nameError != null || ageError != null || asdSeverityError != null) {
      emit(state.copyWith(
        nameError: nameError,
        ageError: ageError,
        asdSeverityError: asdSeverityError,
        status: FormzSubmissionStatus.failure,
        clearServerError: true,
      ));
      return;
    }

    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));

    try {
      final parentId = authRepository.currentUser?.uid;
      if (parentId == null) throw Exception('No parent logged in');

      final childId = await authRepository.addChild(
        parentId: parentId,
        name: state.name.trim(),
        age: ageInt!,
        asdSeverity: state.asdSeverity,
      );

      if (state.therapistEmail.trim().isNotEmpty) {
        await authRepository.sendLinkRequest(
          parentId: parentId,
          childId: childId,
          therapistEmail: state.therapistEmail.trim().toLowerCase(),
        );
      }

      emit(state.copyWith(status: FormzSubmissionStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: FormzSubmissionStatus.failure,
        serverError: e.toString(),
      ));
    }
  }
}