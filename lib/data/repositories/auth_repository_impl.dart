import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/error_handler.dart';
import '../../core/network/network_info.dart';
import '../../core/services/logger_service.dart';
import '../../core/cache/cache_manager.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final CacheManager cacheManager;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.cacheManager,
  });

  @override
  Future<Either<Failure, AuthUser>> login({
    required String email,
    required String password,
  }) async {
    LoggerService.info('Attempting login for email: $email');

    if (!await networkInfo.isConnected) {
      LoggerService.warning('Login failed: No internet connection');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final result = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // 로그인 성공 시 사용자 정보 캐시 저장
      await cacheManager.cacheUserData(result);

      LoggerService.info('Login successful for user: ${result.uid}');
      return Right(result);
    } on FirebaseAuthException catch (e) {
      LoggerService.error('FirebaseAuth error during login', e);
      return Left(ErrorHandler.handleFirebaseAuthError(e));
    } on AuthException catch (e) {
      LoggerService.error('Auth error during login', e);
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      LoggerService.error('Server error during login', e);
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      LoggerService.error('Unexpected error during login', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    LoggerService.info('Attempting registration for email: $email');

    if (!await networkInfo.isConnected) {
      LoggerService.warning('Registration failed: No internet connection');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final result = await remoteDataSource.register(
        email: email,
        password: password,
        name: name,
      );

      // 회원가입 성공 시 사용자 정보 캐시 저장
      await cacheManager.cacheUserData(result);

      LoggerService.info('Registration successful for user: ${result.uid}');
      return Right(result);
    } on FirebaseAuthException catch (e) {
      LoggerService.error('FirebaseAuth error during registration', e);
      return Left(ErrorHandler.handleFirebaseAuthError(e));
    } on AuthException catch (e) {
      LoggerService.error('Auth error during registration', e);
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      LoggerService.error('Server error during registration', e);
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      LoggerService.error('Unexpected error during registration', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    LoggerService.info('Attempting logout');

    try {
      await remoteDataSource.logout();

      // 로그아웃 시 캐시된 사용자 정보 삭제
      await cacheManager.clearUserData();

      LoggerService.info('Logout successful');
      return const Right(null);
    } on AuthException catch (e) {
      LoggerService.error('Auth error during logout', e);
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      LoggerService.error('Unexpected error during logout', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser?>> getCurrentUser() async {
    LoggerService.debug('Getting current user');

    try {
      // 먼저 캐시에서 사용자 정보 확인
      final cachedUser = await cacheManager.getCachedUserData();
      if (cachedUser != null) {
        LoggerService.debug('Found cached user data');
      }

      final result = await remoteDataSource.getCurrentUser();

      // 원격에서 가져온 정보가 있으면 캐시 업데이트
      if (result != null) {
        await cacheManager.cacheUserData(result);
      }

      return Right(result);
    } on AuthException catch (e) {
      LoggerService.error('Auth error while getting current user', e);
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      LoggerService.error('Unexpected error while getting current user', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({required String email}) async {
    LoggerService.info('Attempting password reset for email: $email');

    if (!await networkInfo.isConnected) {
      LoggerService.warning('Password reset failed: No internet connection');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      await remoteDataSource.resetPassword(email: email);
      LoggerService.info('Password reset email sent successfully');
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      LoggerService.error('FirebaseAuth error during password reset', e);
      return Left(ErrorHandler.handleFirebaseAuthError(e));
    } on AuthException catch (e) {
      LoggerService.error('Auth error during password reset', e);
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      LoggerService.error('Unexpected error during password reset', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    LoggerService.info('Sending email verification');

    if (!await networkInfo.isConnected) {
      LoggerService.warning(
          'Email verification failed: No internet connection');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      await remoteDataSource.verifyEmail();
      LoggerService.info('Email verification sent successfully');
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      LoggerService.error('FirebaseAuth error during email verification', e);
      return Left(ErrorHandler.handleFirebaseAuthError(e));
    } on AuthException catch (e) {
      LoggerService.error('Auth error during email verification', e);
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      LoggerService.error('Unexpected error during email verification', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyEmail() async {
    return await sendEmailVerification();
  }

  @override
  Future<Either<Failure, bool>> checkEmailVerification() async {
    LoggerService.debug('Checking email verification status');

    try {
      final user = await remoteDataSource.getCurrentUser();
      if (user == null) {
        return const Left(AuthFailure(message: 'No user logged in'));
      }

      // Firebase에서 최신 사용자 정보 새로고침
      await remoteDataSource.refreshUser();

      final updatedUser = await remoteDataSource.getCurrentUser();
      final isVerified = updatedUser?.emailVerified ?? false;

      LoggerService.debug('Email verification status: $isVerified');
      return Right(isVerified);
    } on AuthException catch (e) {
      LoggerService.error('Auth error while checking email verification', e);
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      LoggerService.error(
          'Unexpected error while checking email verification', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    LoggerService.info('Attempting password change');

    if (!await networkInfo.isConnected) {
      LoggerService.warning('Password change failed: No internet connection');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      await remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      LoggerService.info('Password changed successfully');
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      LoggerService.error('FirebaseAuth error during password change', e);
      return Left(ErrorHandler.handleFirebaseAuthError(e));
    } on AuthException catch (e) {
      LoggerService.error('Auth error during password change', e);
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      LoggerService.error('Unexpected error during password change', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // 소셜 로그인 메서드들
  @override
  Future<Either<Failure, AuthUser>> signInWithGoogle() async {
    LoggerService.info('Attempting Google sign in');

    if (!await networkInfo.isConnected) {
      LoggerService.warning('Google sign in failed: No internet connection');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final result = await remoteDataSource.signInWithGoogle();
      await cacheManager.cacheUserData(result);
      LoggerService.info('Google sign in successful for user: ${result.uid}');
      return Right(result);
    } on FirebaseAuthException catch (e) {
      LoggerService.error('FirebaseAuth error during Google sign in', e);
      return Left(ErrorHandler.handleFirebaseAuthError(e));
    } on AuthException catch (e) {
      LoggerService.error('Auth error during Google sign in', e);
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      LoggerService.error('Unexpected error during Google sign in', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> signInWithApple() async {
    LoggerService.info('Attempting Apple sign in');

    if (!await networkInfo.isConnected) {
      LoggerService.warning('Apple sign in failed: No internet connection');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final result = await remoteDataSource.signInWithApple();
      await cacheManager.cacheUserData(result);
      LoggerService.info('Apple sign in successful for user: ${result.uid}');
      return Right(result);
    } on FirebaseAuthException catch (e) {
      LoggerService.error('FirebaseAuth error during Apple sign in', e);
      return Left(ErrorHandler.handleFirebaseAuthError(e));
    } on AuthException catch (e) {
      LoggerService.error('Auth error during Apple sign in', e);
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      LoggerService.error('Unexpected error during Apple sign in', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> signInWithFacebook() async {
    LoggerService.info('Attempting Facebook sign in');

    if (!await networkInfo.isConnected) {
      LoggerService.warning('Facebook sign in failed: No internet connection');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final result = await remoteDataSource.signInWithFacebook();
      await cacheManager.cacheUserData(result);
      LoggerService.info('Facebook sign in successful for user: ${result.uid}');
      return Right(result);
    } on FirebaseAuthException catch (e) {
      LoggerService.error('FirebaseAuth error during Facebook sign in', e);
      return Left(ErrorHandler.handleFirebaseAuthError(e));
    } on AuthException catch (e) {
      LoggerService.error('Auth error during Facebook sign in', e);
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      LoggerService.error('Unexpected error during Facebook sign in', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    LoggerService.info('Attempting account deletion');

    if (!await networkInfo.isConnected) {
      LoggerService.warning('Account deletion failed: No internet connection');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      await remoteDataSource.deleteAccount();
      await cacheManager.clearUserData();
      LoggerService.info('Account deleted successfully');
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      LoggerService.error('FirebaseAuth error during account deletion', e);
      return Left(ErrorHandler.handleFirebaseAuthError(e));
    } on AuthException catch (e) {
      LoggerService.error('Auth error during account deletion', e);
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      LoggerService.error('Unexpected error during account deletion', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    LoggerService.info('Attempting profile update');

    if (!await networkInfo.isConnected) {
      LoggerService.warning('Profile update failed: No internet connection');
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      await remoteDataSource.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );

      // 프로필 업데이트 후 캐시 갱신
      final updatedUser = await remoteDataSource.getCurrentUser();
      if (updatedUser != null) {
        await cacheManager.cacheUserData(updatedUser);
      }

      LoggerService.info('Profile updated successfully');
      return const Right(null);
    } on AuthException catch (e) {
      LoggerService.error('Auth error during profile update', e);
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      LoggerService.error('Unexpected error during profile update', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    LoggerService.debug('Setting up auth state changes stream');
    return remoteDataSource.authStateChanges.map((user) {
      if (user != null) {
        // 상태 변경 시 캐시 업데이트 (비동기)
        cacheManager.cacheUserData(user).catchError((error) {
          LoggerService.error('Failed to cache user data from stream', error);
        });
      } else {
        // 로그아웃 시 캐시 삭제 (비동기)
        cacheManager.clearUserData().catchError((error) {
          LoggerService.error('Failed to clear cached user data', error);
        });
      }
      return user;
    });
  }
}
