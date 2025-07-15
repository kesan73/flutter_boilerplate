import 'package:shared_preferences/shared_preferences.dart';
import '../core/errors/exceptions.dart';

abstract class StorageService {
  Future<void> storeString(String key, String value);
  Future<String?> getString(String key);
  Future<void> storeBool(String key, bool value);
  Future<bool?> getBool(String key);
  Future<void> storeInt(String key, int value);
  Future<int?> getInt(String key);
  Future<void> remove(String key);
  Future<void> clear();
}

class StorageServiceImpl implements StorageService {
  final SharedPreferences _prefs;

  StorageServiceImpl(this._prefs);

  @override
  Future<void> storeString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } catch (e) {
      throw CacheException(message: 'Failed to store string: ${e.toString()}');
    }
  }

  @override
  Future<String?> getString(String key) async {
    try {
      return _prefs.getString(key);
    } catch (e) {
      throw CacheException(message: 'Failed to get string: ${e.toString()}');
    }
  }

  @override
  Future<void> storeBool(String key, bool value) async {
    try {
      await _prefs.setBool(key, value);
    } catch (e) {
      throw CacheException(message: 'Failed to store bool: ${e.toString()}');
    }
  }

  @override
  Future<bool?> getBool(String key) async {
    try {
      return _prefs.getBool(key);
    } catch (e) {
      throw CacheException(message: 'Failed to get bool: ${e.toString()}');
    }
  }

  @override
  Future<void> storeInt(String key, int value) async {
    try {
      await _prefs.setInt(key, value);
    } catch (e) {
      throw CacheException(message: 'Failed to store int: ${e.toString()}');
    }
  }

  @override
  Future<int?> getInt(String key) async {
    try {
      return _prefs.getInt(key);
    } catch (e) {
      throw CacheException(message: 'Failed to get int: ${e.toString()}');
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _prefs.remove(key);
    } catch (e) {
      throw CacheException(message: 'Failed to remove key: ${e.toString()}');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _prefs.clear();
    } catch (e) {
      throw CacheException(message: 'Failed to clear storage: ${e.toString()}');
    }
  }
}
