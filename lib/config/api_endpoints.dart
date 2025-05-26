class ApiEndpoints {
  // Base URL
  static const String baseUrl = 'http://192.168.1.159:3000/api';

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String doctors = '/auth/users';

  // User endpoints
  static const String users = '/users';
  static const String patientsWhoMessaged = '/users/patients/messaged';
  static const String allDoctors = '/users?role=doctor';

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

  // Review endpoints
  static const String reviews = '/reviews';
  static const String doctorReviews = '/reviews/doctor';

  // Calendar management endpoints
  static const String calendar = '/calendar';
  static const String calendarWorkingHours = '/calendar/working-hours';
  static const String calendarDate = '/calendar/date';
  static const String calendarBlockSlot = '/calendar/block-slot';
  static const String calendarAvailableSlots = '/calendar/available-slots';

  // Todo endpoints
  static const String todos = '/todos';
  static const String todoToggle = '/todos/:id/toggle';

  // Message endpoints
  static const String messages = '/messages';
  static const String conversations = '/messages/conversations';
  static const String unreadCount = '/messages/unread/count';
  static const String searchMessages = '/messages/search';
  static const String messageReactions = '/messages/:id/reactions';
  static const String messageForward = '/messages/:id/forward';
  static const String messageRead = '/messages/:id/read';

  // File upload
  static const String fileMessages = '/messages/file';
  static const String fileMessagesBase64 = '/messages/file/base64';

  // AI Health Assistant endpoints
  static const String healthInsightsSessions = '/health-insights/sessions';
  static const String healthInsightsMessages = '/health-insights/messages';
  static const String healthInsightsSampleTopics =
      '/health-insights/sample-topics';
  static const String healthInsightsAnalyzeImage =
      '/health-insights/analyze-image';
  static const String healthInsightsAnalyzeDocument =
      '/health-insights/analyze-document';
}
