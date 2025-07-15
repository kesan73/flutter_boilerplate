class AppConfig {
  static const String appName = 'Boilerplate App';
  static const String version = '1.0.0';
  static const int timeoutDuration = 30;
  static const String baseUrl = 'https://api.example.com';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String authCollection = 'auth';

  // SharedPreferences Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String isFirstTimeKey = 'is_first_time';

  // Error Messages
  static const String networkErrorMessage = 'No internet connection';
  static const String serverErrorMessage = 'Server error occurred';
  static const String unknownErrorMessage = 'Unknown error occurred';
}
