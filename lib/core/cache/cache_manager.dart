// lib/core/cache/cache_manager.dart - 업데이트된 버전
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/user.dart';
import '../services/logger_service.dart';

class CacheManager {
  static const String _userCacheKey = 'cached_user_data';
  static const String _authUserCacheKey = 'cached_auth_user_data';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _lastLoginKey = 'last_login_timestamp';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  final SharedPreferences _prefs;

  CacheManager(this._prefs);

  // AuthUser 데이터 캐싱
  Future<void> cacheUserData(AuthUser user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _prefs.setString(_authUserCacheKey, userJson);
      await _prefs.setInt(_lastLoginKey, DateTime.now().millisecondsSinceEpoch);
      LoggerService.debug('AuthUser data cached successfully');
    } catch (e) {
      LoggerService.error('Failed to cache AuthUser data', e);
      rethrow;
    }
  }

  // 캐시된 AuthUser 데이터 가져오기
  Future<AuthUser?> getCachedUserData() async {
    try {
      final userJson = _prefs.getString(_authUserCacheKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        LoggerService.debug('Retrieved cached AuthUser data');
        return AuthUser.fromJson(userMap);
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to get cached AuthUser data', e);
      return null;
    }
  }

  // User Profile 데이터 캐싱
  Future<void> cacheUserProfile(User user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _prefs.setString(_userCacheKey, userJson);
      LoggerService.debug('User profile cached successfully');
    } catch (e) {
      LoggerService.error('Failed to cache User profile', e);
      rethrow;
    }
  }

  // 캐시된 User Profile 데이터 가져오기
  Future<User?> getCachedUserProfile() async {
    try {
      final userJson = _prefs.getString(_userCacheKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        LoggerService.debug('Retrieved cached User profile');
        return User.fromJson(userMap);
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to get cached User profile', e);
      return null;
    }
  }

  // 사용자 데이터 캐시 삭제
  Future<void> clearUserData() async {
    try {
      await _prefs.remove(_authUserCacheKey);
      await _prefs.remove(_userCacheKey);
      await _prefs.remove(_lastLoginKey);
      await _prefs.remove(_tokenKey);
      await _prefs.remove(_refreshTokenKey);
      LoggerService.debug('User data cache cleared');
    } catch (e) {
      LoggerService.error('Failed to clear user data cache', e);
      rethrow;
    }
  }

  // 토큰 저장
  Future<void> cacheAuthToken(String token) async {
    try {
      await _prefs.setString(_tokenKey, token);
      LoggerService.debug('Auth token cached');
    } catch (e) {
      LoggerService.error('Failed to cache auth token', e);
      rethrow;
    }
  }

  // 토큰 가져오기
  Future<String?> getCachedAuthToken() async {
    try {
      return _prefs.getString(_tokenKey);
    } catch (e) {
      LoggerService.error('Failed to get cached auth token', e);
      return null;
    }
  }

  // 리프레시 토큰 저장
  Future<void> cacheRefreshToken(String refreshToken) async {
    try {
      await _prefs.setString(_refreshTokenKey, refreshToken);
      LoggerService.debug('Refresh token cached');
    } catch (e) {
      LoggerService.error('Failed to cache refresh token', e);
      rethrow;
    }
  }

  // 리프레시 토큰 가져오기
  Future<String?> getCachedRefreshToken() async {
    try {
      return _prefs.getString(_refreshTokenKey);
    } catch (e) {
      LoggerService.error('Failed to get cached refresh token', e);
      return null;
    }
  }

  // 마지막 로그인 시간 가져오기
  Future<DateTime?> getLastLoginTime() async {
    try {
      final timestamp = _prefs.getInt(_lastLoginKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to get last login time', e);
      return null;
    }
  }

  // 사용자 설정 저장
  Future<void> cacheUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final preferencesJson = jsonEncode(preferences);
      await _prefs.setString(_userPreferencesKey, preferencesJson);
      LoggerService.debug('User preferences cached');
    } catch (e) {
      LoggerService.error('Failed to cache user preferences', e);
      rethrow;
    }
  }

  // 사용자 설정 가져오기
  Future<Map<String, dynamic>?> getCachedUserPreferences() async {
    try {
      final preferencesJson = _prefs.getString(_userPreferencesKey);
      if (preferencesJson != null) {
        return jsonDecode(preferencesJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to get cached user preferences', e);
      return null;
    }
  }

  // 캐시 유효성 검사 (예: 7일)
  Future<bool> isCacheValid() async {
    try {
      final lastLogin = await getLastLoginTime();
      if (lastLogin == null) return false;

      final now = DateTime.now();
      final difference = now.difference(lastLogin);

      // 7일 이내의 캐시만 유효하다고 판단
      return difference.inDays < 7;
    } catch (e) {
      LoggerService.error('Failed to check cache validity', e);
      return false;
    }
  }

  // 모든 캐시 삭제
  Future<void> clearAllCache() async {
    try {
      await _prefs.clear();
      LoggerService.debug('All cache cleared');
    } catch (e) {
      LoggerService.error('Failed to clear all cache', e);
      rethrow;
    }
  }

  // 특정 키의 캐시 존재 여부 확인
  bool hasCache(String key) {
    return _prefs.containsKey(key);
  }

  // 캐시 크기 정보 (대략적)
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final keys = _prefs.getKeys();
      final info = <String, dynamic>{};

      for (final key in keys) {
        final value = _prefs.get(key);
        if (value != null) {
          info[key] = {
            'type': value.runtimeType.toString(),
            'size': value.toString().length,
          };
        }
      }

      return info;
    } catch (e) {
      LoggerService.error('Failed to get cache info', e);
      return {};
    }
  }

  // 캐시 데이터 동기화 상태 확인
  Future<bool> isDataSynced() async {
    try {
      final authUser = await getCachedUserData();
      final userProfile = await getCachedUserProfile();

      // 두 데이터가 모두 존재하고 이메일이 일치하는지 확인
      if (authUser != null && userProfile != null) {
        return authUser.email == userProfile.email;
      }

      return false;
    } catch (e) {
      LoggerService.error('Failed to check data sync status', e);
      return false;
    }
  }

  // 개별 캐시 삭제 메서드들
  Future<void> clearAuthUserCache() async {
    try {
      await _prefs.remove(_authUserCacheKey);
      LoggerService.debug('AuthUser cache cleared');
    } catch (e) {
      LoggerService.error('Failed to clear AuthUser cache', e);
      rethrow;
    }
  }

  Future<void> clearUserProfileCache() async {
    try {
      await _prefs.remove(_userCacheKey);
      LoggerService.debug('User profile cache cleared');
    } catch (e) {
      LoggerService.error('Failed to clear User profile cache', e);
      rethrow;
    }
  }

  Future<void> clearTokens() async {
    try {
      await _prefs.remove(_tokenKey);
      await _prefs.remove(_refreshTokenKey);
      LoggerService.debug('Tokens cleared');
    } catch (e) {
      LoggerService.error('Failed to clear tokens', e);
      rethrow;
    }
  }
}
