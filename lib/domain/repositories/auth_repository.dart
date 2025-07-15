import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  // 기본 인증
  Future<Either<Failure, AuthUser>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthUser>> register({
    required String email,
    required String password,
    required String name,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, AuthUser?>> getCurrentUser();

  // 비밀번호 관련
  Future<Either<Failure, void>> resetPassword({required String email});
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  // 이메일 인증
  Future<Either<Failure, void>> sendEmailVerification();
  Future<Either<Failure, void>> verifyEmail();
  Future<Either<Failure, bool>> checkEmailVerification();

  // 소셜 로그인
  Future<Either<Failure, AuthUser>> signInWithGoogle();
  Future<Either<Failure, AuthUser>> signInWithApple();
  Future<Either<Failure, AuthUser>> signInWithFacebook();

  // 계정 관리
  Future<Either<Failure, void>> deleteAccount();
  Future<Either<Failure, void>> updateProfile({
    String? displayName,
    String? photoURL,
  });

  // 상태 스트림
  Stream<AuthUser?> get authStateChanges;
}
