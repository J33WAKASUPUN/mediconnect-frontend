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
  
  // Appointment endpoints
  static const String appointments = '/appointments';
  static const String appointmentsByUser = '/appointments/user';
  static const String appointmentsByDoctor = '/appointments/doctor';
  
  // Payment endpoints
  static const String payments = '/payments';
  static const String paymentVerify = '/payments/verify';
  
  // Medical Records endpoints
  static const String medicalRecords = '/medical-records';
  static const String patientMedicalRecords = '/medical-records/patient';
  
  // Notification endpoints
  static const String notifications = '/notifications';
  
  // Helper method to get full URL
  static String getFullUrl(String endpoint) => baseUrl + endpoint;
}