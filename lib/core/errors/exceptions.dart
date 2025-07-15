class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  // 수정: 첫 번째 위치 매개변수 제거, message만 명명 매개변수로 사용
  const ServerException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() =>
      'ServerException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}${errorCode != null ? ' (Code: $errorCode)' : ''}';
}

class NetworkException implements Exception {
  final String message;
  final String? errorCode;

  const NetworkException({
    required this.message,
    this.errorCode,
  });

  @override
  String toString() =>
      'NetworkException: $message${errorCode != null ? ' (Code: $errorCode)' : ''}';
}

class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

enum AuthExceptionType {
  general,
  invalidCredentials,
  userNotFound,
  emailAlreadyInUse,
  weakPassword,
  networkError,
  userDisabled,
  tooManyRequests,
}

class AuthException implements Exception {
  final String message;
  final String? code;
  final AuthExceptionType type;

  const AuthException({
    required this.message,
    this.code,
    this.type = AuthExceptionType.general,
  });

  @override
  String toString() =>
      'AuthException: $message${code != null ? ' (Code: $code)' : ''}';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? errors;

  const ValidationException({
    required this.message,
    this.errors,
  });

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      final errorDetails =
          errors!.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      return 'ValidationException: $message (Errors: $errorDetails)';
    }
    return 'ValidationException: $message';
  }
}
