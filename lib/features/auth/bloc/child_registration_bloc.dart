import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'child_registration_event.dart';
import 'child_registration_state.dart';
import '../../../features/auth/data/auth_repository.dart';



class ChildRegistrationBloc extends Bloc<ChildRegistrationEvent, ChildRegistrationState> {
  final AuthRepository authRepository;

  ChildRegistrationBloc({required this.authRepository})
      : super(const ChildRegistrationState()) {
    on<ChildNameChanged>(_onNameChanged);
    on<ChildAgeChanged>(_onAgeChanged);
    on<ChildSeverityChanged>(_onSeverityChanged);
    on<ChildGenderChanged>(_onGenderChanged);
    on<ChildTherapistEmailChanged>(_onTherapistEmailChanged);
    on<ChildRegistrationSubmitted>(_onSubmitted);
  }

  void _onNameChanged(ChildNameChanged event, Emitter<ChildRegistrationState> emit) {
    final error = event.name.isEmpty ? 'Name cannot be empty' : null;
    emit(state.copyWith(name: event.name, nameError: error));
  }

  void _onAgeChanged(ChildAgeChanged event, Emitter<ChildRegistrationState> emit) {
    final ageInt = int.tryParse(event.age);
    final error = (ageInt == null || ageInt <= 0) ? 'Enter a valid age' : null;
    emit(state.copyWith(age: event.age, ageError: error));
  }

  void _onSeverityChanged(ChildSeverityChanged event, Emitter<ChildRegistrationState> emit) {
    emit(state.copyWith(asdSeverity: event.severity));
  }

  void _onGenderChanged(ChildGenderChanged event, Emitter<ChildRegistrationState> emit) {
    emit(state.copyWith(gender: event.gender));
  }

  void _onTherapistEmailChanged(ChildTherapistEmailChanged event, Emitter<ChildRegistrationState> emit) {
    emit(state.copyWith(therapistEmail: event.email));
  }

  Future<void> _onSubmitted(
  ChildRegistrationSubmitted event,
  Emitter<ChildRegistrationState> emit,
) async {
  // Validate before trying to parse
  final nameError = state.name.trim().isEmpty ? 'Name cannot be empty' : null;
  final ageInt = int.tryParse(state.age.trim()); // tryParse instead of parse — never throws
  final ageError = (ageInt == null || ageInt <= 0 || ageInt > 18)
      ? 'Enter a valid age (1–18)'
      : null;

  if (nameError != null || ageError != null) {
    emit(state.copyWith(
      nameError: nameError,
      ageError: ageError,
      status: FormzSubmissionStatus.failure,
    ));
    return;
  }

  emit(state.copyWith(status: FormzSubmissionStatus.inProgress));

  try {
    final parentId = authRepository.currentUser?.uid;

    if (parentId == null) {
      throw Exception('No parent logged in');
    }

    await authRepository.addChild(
      parentId: parentId,
      name: state.name.trim(),
      age: ageInt!, // safe — already validated above
      asdSeverity: state.asdSeverity,
    );

    emit(state.copyWith(status: FormzSubmissionStatus.success));
  } catch (e) {
    emit(state.copyWith(
      status: FormzSubmissionStatus.failure,
      serverError: e.toString(),
    ));
  }
}}