class InputSanitizer {
  // XSS 방지를 위한 HTML 태그 제거
  static String sanitizeHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  // SQL 인젝션 방지를 위한 특수문자 이스케이프
  static String escapeSqlString(String input) {
    return input.replaceAll("'", "''").replaceAll('"', '""');
  }

  // 입력값 정규화
  static String normalizeInput(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // 이메일 정규화
  static String normalizeEmail(String email) {
    return email.toLowerCase().trim();
  }

  // 전화번호 정규화 (한국 형식)
  static String normalizePhoneNumber(String phone) {
    String normalized = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (normalized.startsWith('010')) {
      return '+82${normalized.substring(1)}';
    }
    return normalized;
  }
}
