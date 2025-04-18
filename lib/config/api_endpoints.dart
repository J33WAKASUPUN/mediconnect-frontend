class ApiEndpoints {
  // Base URL
  static const String baseUrl = 'http://192.168.1.159:3000/api';
  
  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String doctors = '/auth/users'; 
  
  // Profile endpoints
  static const String profile = '/profile';
  static const String patientProfile = '/profile/patient';
  static const String doctorProfile = '/profile/doctor';
  
  // Helper method to get full URL
  static String getFullUrl(String endpoint) => baseUrl + endpoint;
}