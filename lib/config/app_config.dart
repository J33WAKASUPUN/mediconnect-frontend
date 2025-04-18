class AppConfig {
  // App Name
  static const String appName = 'MediConnect';
  
  // SharedPreferences Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  // DateTime Format
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  
  // Default Values
  static const String defaultProfileImage = 'assets/images/default_profile.png';
  
  // Validation Rules
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int phoneLength = 10;
}