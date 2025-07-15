import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // 보안 저장소에 토큰 저장
  static Future<void> storeToken(String key, String token) async {
    await _storage.write(key: key, value: token);
  }

  // 보안 저장소에서 토큰 읽기
  static Future<String?> getToken(String key) async {
    return await _storage.read(key: key);
  }

  // 토큰 삭제
  static Future<void> deleteToken(String key) async {
    await _storage.delete(key: key);
  }

  // 모든 토큰 삭제
  static Future<void> deleteAllTokens() async {
    await _storage.deleteAll();
  }

  // 비밀번호 강도 검사
  static PasswordStrength checkPasswordStrength(String password) {
    if (password.length < 8) return PasswordStrength.weak;

    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasNumbers = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int score = 0;
    if (hasUppercase) score++;
    if (hasLowercase) score++;
    if (hasNumbers) score++;
    if (hasSpecialCharacters) score++;

    if (password.length >= 12) score++;

    switch (score) {
      case 0:
      case 1:
      case 2:
        return PasswordStrength.weak;
      case 3:
        return PasswordStrength.medium;
      case 4:
      case 5:
        return PasswordStrength.strong;
      default:
        return PasswordStrength.weak;
    }
  }

  // 난수 생성
  static String generateSecureRandom(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  // 해시 생성
  static String generateHash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // 생체 인증 체크 (flutter_local_auth 패키지 필요)
  // static Future<bool> authenticateWithBiometrics() async {
  //   final localAuth = LocalAuthentication();
  //   try {
  //     final isAvailable = await localAuth.canCheckBiometrics;
  //     if (!isAvailable) return false;
  //
  //     final result = await localAuth.authenticate(
  //       localizedReason: '생체 인증을 진행해주세요',
  //       options: const AuthenticationOptions(
  //         biometricOnly: true,
  //       ),
  //     );
  //     return result;
  //   } catch (e) {
  //     return false;
  //   }
  // }
}

enum PasswordStrength { weak, medium, strong }
