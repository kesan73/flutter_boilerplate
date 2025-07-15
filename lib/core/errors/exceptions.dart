class ServerException implements Exception {
  final String message;
  final int? statusCode;

  // 수정: 첫 번째 위치 매개변수 제거, message만 명명 매개변수로 사용
  const ServerException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() =>
      'ServerException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException({
    required this.message,
    this.code,
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
