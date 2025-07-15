// lib/presentation/blocs/auth/auth_bloc.dart - 업데이트된 버전
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/auth/login_usecase.dart';
import '../../../domain/usecases/auth/register_usecase.dart';
import '../../../domain/usecases/auth/logout_usecase.dart';
import '../../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../../domain/usecases/auth/reset_password_usecase.dart';
import '../../../domain/usecases/auth/verify_email_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final VerifyEmailUseCase verifyEmailUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.resetPasswordUseCase,
    required this.verifyEmailUseCase,
  }) : super(AuthInitial()) {
    // 핵심 인증 이벤트 핸들러들
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatusRequested>(_onCheckAuthStatusRequested);
    on<AuthStatusChanged>(_onAuthStatusChanged);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<VerifyEmailRequested>(_onVerifyEmailRequested);

    // UI 이벤트 핸들러들 (하위 호환성을 위해)
    on<LoginEvent>((event, emit) => add(LoginRequested(
          email: event.email,
          password: event.password,
        )));
    on<RegisterEvent>((event, emit) => add(RegisterRequested(
          email: event.email,
          password: event.password,
          name: event.name,
        )));
    on<LogoutEvent>((event, emit) => add(LogoutRequested()));
    on<CheckAuthStatusEvent>((event, emit) => add(CheckAuthStatusRequested()));
    on<ResetPasswordEvent>(
        (event, emit) => add(ResetPasswordRequested(email: event.email)));
    on<ForgotPasswordEvent>(
        (event, emit) => add(ResetPasswordRequested(email: event.email)));
    on<VerifyEmailEvent>((event, emit) => add(VerifyEmailRequested()));
  }

  /// Handle login request
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await loginUseCase(
      LoginParams(
        email: event.email,
        password: event.password,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  /// Handle register request
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await registerUseCase(
      RegisterParams(
        email: event.email,
        password: event.password,
        name: event.name,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  /// Handle logout request
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await logoutUseCase(NoParams());

    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (_) => emit(AuthUnauthenticated()),
    );
  }

  /// Check current authentication status
  Future<void> _onCheckAuthStatusRequested(
    CheckAuthStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await getCurrentUserUseCase(NoParams());

    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) {
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthUnauthenticated());
        }
      },
    );
  }

  /// Handle authentication status changes (e.g., from Firebase auth state listener)
  void _onAuthStatusChanged(
    AuthStatusChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      emit(AuthAuthenticated(event.user!));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  /// Handle password reset request
  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await resetPasswordUseCase(
      ResetPasswordParams(email: event.email),
    );

    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (_) => emit(AuthPasswordResetSent(event.email)),
    );
  }

  /// Handle email verification request
  Future<void> _onVerifyEmailRequested(
    VerifyEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await verifyEmailUseCase(NoParams());

    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (_) => emit(AuthEmailVerificationSent()),
    );
  }

  /// Map failure types to user-friendly error messages
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case const (ServerFailure):
        return 'Server error occurred. Please try again later.';
      case NetworkFailure:
        return 'Network error. Please check your internet connection.';
      case CacheFailure:
        return 'Cache error occurred.';
      case AuthFailure:
        final authFailure = failure as AuthFailure;
        return _getAuthErrorMessage(authFailure);
      case ValidationFailure:
        return 'Invalid input provided.';
      default:
        return 'An unexpected error occurred.';
    }
  }

  /// Get specific auth error messages
  String _getAuthErrorMessage(AuthFailure failure) {
    switch (failure.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'requires-recent-login':
        return 'Please log in again to continue.';
      default:
        return failure.message;
    }
  }
}
