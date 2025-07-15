import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'failures.dart';
import '../services/logger_service.dart';

class ErrorHandler {
  static Failure handleFirebaseAuthError(FirebaseAuthException e) {
    LoggerService.error('FirebaseAuth Error: ${e.code} - ${e.message}');

    switch (e.code) {
      case 'user-not-found':
        return const AuthFailure(message: '등록되지 않은 이메일입니다.');
      case 'wrong-password':
        return const AuthFailure(message: '비밀번호가 올바르지 않습니다.');
      case 'email-already-in-use':
        return const AuthFailure(message: '이미 사용 중인 이메일입니다.');
      case 'weak-password':
        return const AuthFailure(message: '비밀번호가 너무 약합니다.');
      case 'invalid-email':
        return const AuthFailure(message: '유효하지 않은 이메일 형식입니다.');
      case 'user-disabled':
        return const AuthFailure(message: '비활성화된 계정입니다.');
      case 'too-many-requests':
        return const AuthFailure(message: '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.');
      case 'operation-not-allowed':
        return const AuthFailure(message: '허용되지 않은 작업입니다.');
      case 'requires-recent-login':
        return const AuthFailure(message: '보안을 위해 다시 로그인해주세요.');
      default:
        return AuthFailure(message: e.message ?? '인증 오류가 발생했습니다.');
    }
  }

  static Failure handleFirestoreError(FirebaseException e) {
    LoggerService.error('Firestore Error: ${e.code} - ${e.message}');

    switch (e.code) {
      case 'permission-denied':
        return const ServerFailure(message: '권한이 없습니다.');
      case 'unavailable':
        return const NetworkFailure(message: '서버에 연결할 수 없습니다.');
      case 'deadline-exceeded':
        return const NetworkFailure(message: '요청 시간이 초과되었습니다.');
      case 'not-found':
        return const ServerFailure(message: '요청한 데이터를 찾을 수 없습니다.');
      case 'already-exists':
        return const ServerFailure(message: '이미 존재하는 데이터입니다.');
      default:
        return ServerFailure(message: e.message ?? '서버 오류가 발생했습니다.');
    }
  }

  static Failure handleGenericError(dynamic error) {
    LoggerService.error('Generic Error: $error');

    if (error is FirebaseAuthException) {
      return handleFirebaseAuthError(error);
    } else if (error is FirebaseException) {
      return handleFirestoreError(error);
    } else {
      return UnknownFailure(message: error.toString());
    }
  }
}
