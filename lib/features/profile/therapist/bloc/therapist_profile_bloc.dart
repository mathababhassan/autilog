import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/data/auth_repository.dart';
import '../data/therapist_repository.dart';
import '../../../../shared/models/therapist_model.dart';
import '../../../../shared/models/user_model.dart';
import 'therapist_profile_event.dart';
import 'therapist_profile_state.dart';

class TherapistProfileBloc
    extends Bloc<TherapistProfileEvent, TherapistProfileState> {
  TherapistProfileBloc({
    required TherapistRepository therapistRepository,
    required AuthRepository authRepository,
  })  : _therapistRepository = therapistRepository,
        _authRepository = authRepository,
        super(const TherapistProfileInitial()) {
    on<TherapistProfileStarted>(_onStarted);
    on<TherapistProfileUpdateRequested>(_onUpdateRequested);
    on<TherapistProfileDeleteRequested>(_onDeleteRequested);
    on<TherapistProfileSignOutRequested>(_onSignOutRequested);
  }

  final TherapistRepository _therapistRepository;
  final AuthRepository _authRepository;

  Future<void> _onStarted(
    TherapistProfileStarted event,
    Emitter<TherapistProfileState> emit,
  ) async {
    emit(const TherapistProfileLoading());
    try {
      final uid = _authRepository.currentUser!.uid;
      final profile = await _therapistRepository.fetchProfile(uid);
      emit(TherapistProfileLoaded(
        therapist: profile.therapist,
        user: profile.user,
      ));
    } catch (e) {
      emit(TherapistProfileError(message: e.toString()));
    }
  }

  Future<void> _onUpdateRequested(
    TherapistProfileUpdateRequested event,
    Emitter<TherapistProfileState> emit,
  ) async {
    final current = state;
    if (current is! TherapistProfileLoaded &&
        current is! TherapistProfileUpdateSuccess) {
      return;
    }

    final TherapistModel therapist;
    final UserModel user;
    if (current is TherapistProfileLoaded) {
      therapist = current.therapist;
      user = current.user;
    } else {
      therapist = (current as TherapistProfileUpdateSuccess).therapist;
      user = current.user;
    }

    emit(TherapistProfileUpdating(therapist: therapist, user: user));
    try {
      final uid = _authRepository.currentUser!.uid;
      await _therapistRepository.updateProfile(uid, event.fields);
      final updated = therapist.copyWith(
        name: event.fields['name'] as String?,
        clinicName: event.fields['clinicName'] as String?,
        specialisation: event.fields['specialisation'] as String?,
        phone: event.fields['phone'] as String?,
        experience: event.fields['experience'] as String?,
      );
      emit(TherapistProfileUpdateSuccess(therapist: updated, user: user));
    } catch (e) {
      emit(TherapistProfileLoaded(therapist: therapist, user: user));
      emit(TherapistProfileError(message: e.toString()));
    }
  }

  Future<void> _onDeleteRequested(
    TherapistProfileDeleteRequested event,
    Emitter<TherapistProfileState> emit,
  ) async {
    final current = state;
    if (current is! TherapistProfileLoaded &&
        current is! TherapistProfileUpdateSuccess) {
      return;
    }

    final UserModel user = current is TherapistProfileLoaded
        ? current.user
        : (current as TherapistProfileUpdateSuccess).user;

    emit(const TherapistProfileDeleting());
    try {
      final uid = _authRepository.currentUser!.uid;
      await _therapistRepository.deleteProfile(uid, user.email);
      emit(const TherapistProfileDeleted());
    } catch (e) {
      emit(TherapistProfileError(message: e.toString()));
    }
  }

  Future<void> _onSignOutRequested(
    TherapistProfileSignOutRequested event,
    Emitter<TherapistProfileState> emit,
  ) async {
    try {
      await _authRepository.logout();
      emit(const TherapistProfileSignedOut());
    } catch (e) {
      emit(TherapistProfileError(message: e.toString()));
    }
  }
}
