class AppConstants {
  // App Info
  static const String appName = 'Boilerplate App';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String baseUrl = 'https://api.example.com';
  static const String authEndpoint = '/auth';
  static const String userEndpoint = '/user';

  // Pagination
  static const int pageSize = 20;
  static const int maxPageSize = 100;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxEmailLength = 100;

  // Timeouts
  static const int networkTimeout = 30000; // 30 seconds
  static const int cacheTimeout = 300000; // 5 minutes

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 8.0;
  static const double defaultBorderRadius = 12.0;

  // Animation Durations
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 400;
  static const int longAnimationDuration = 600;
}
