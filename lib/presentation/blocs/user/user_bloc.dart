import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/user/get_user_profile_usecase.dart';
import '../../../domain/usecases/user/update_user_profile_usecase.dart';
import '../../../core/errors/failures.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUserProfileUseCase getUserProfileUseCase;
  final UpdateUserProfileUseCase updateUserProfileUseCase;

  UserBloc({
    required this.getUserProfileUseCase,
    required this.updateUserProfileUseCase,
  }) : super(UserInitial()) {
    on<GetUserProfileEvent>(_onGetUserProfile);
    on<UpdateUserProfileEvent>(_onUpdateUserProfile);
    on<ClearUserEvent>(_onClearUser);
  }

  Future<void> _onGetUserProfile(
    GetUserProfileEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    final result = await getUserProfileUseCase(
      GetUserProfileParams(userId: event.userId),
    );

    result.fold(
      (failure) => emit(UserError(_mapFailureToMessage(failure))),
      (user) => emit(UserLoaded(user)),
    );
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfileEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    final result = await updateUserProfileUseCase(
      UpdateUserProfileParams(
        userId: event.userId,
        userData: event.userData,
        data: {},
      ),
    );

    result.fold(
      (failure) => emit(UserError(_mapFailureToMessage(failure))),
      (user) => emit(UserUpdated(user)),
    );
  }

  void _onClearUser(ClearUserEvent event, Emitter<UserState> emit) {
    emit(UserInitial());
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server Error. Please try again later.';
      case CacheFailure:
        return 'Cache Error. Please try again.';
      case NetworkFailure:
        return 'Network Error. Please check your connection.';
      default:
        return 'Unexpected Error. Please try again.';
    }
  }
}
