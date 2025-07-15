class FirebaseConstants {
  // Collections
  static const String usersCollection = 'users';
  static const String authTokensCollection = 'auth_tokens';
  static const String userProfilesCollection = 'user_profiles';

  // Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String documentsPath = 'documents';

  // Field Names
  static const String emailField = 'email';
  static const String nameField = 'name';
  static const String createdAtField = 'createdAt';
  static const String updatedAtField = 'updatedAt';
  static const String isActiveField = 'isActive';
  static const String profileImageUrlField = 'profileImageUrl';
  static const String phoneNumberField = 'phoneNumber';
  static const String birthdateField = 'birthdate';
  static const String genderField = 'gender';

  // Auth Provider IDs
  static const String emailProvider = 'password';
  static const String googleProvider = 'google.com';
  static const String facebookProvider = 'facebook.com';
  static const String appleProvider = 'apple.com';
}
