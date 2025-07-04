import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediconnect/core/services/auth_service.dart';
import 'package:mediconnect/core/services/health_ai_service.dart';
import 'package:mediconnect/core/services/message_service.dart';
import 'package:mediconnect/core/services/socket_service.dart';
import 'package:mediconnect/core/services/user_service.dart';
import 'package:mediconnect/features/doctor/screens/patient_profile_screen.dart';
import 'package:mediconnect/features/doctor/screens/patient_list_screen.dart';
import 'package:mediconnect/features/doctor_calendar/provider/calender_provider.dart';
import 'package:mediconnect/features/doctor_calendar/provider/todo_provider.dart';
import 'package:mediconnect/features/doctor_calendar/screens/doctor_calendar.dart';
import 'package:mediconnect/features/doctor_calendar/screens/working_hours_settings.dart';
import 'package:mediconnect/features/health_ai/providers/health_ai_provider.dart';
import 'package:mediconnect/features/health_ai/screens/health_sessions_screen.dart';
import 'package:mediconnect/features/medication_reminder/provider/medication_reminder_provider.dart';
import 'package:mediconnect/features/messages/provider/conversation_provider.dart';
import 'package:mediconnect/features/messages/provider/message_provider.dart';
import 'package:mediconnect/features/messages/screens/chat_detail_screen.dart';
import 'package:mediconnect/features/messages/screens/chat_list_screen.dart';
import 'package:mediconnect/features/messages/screens/doctor_contacts_screen.dart';
import 'package:mediconnect/features/messages/screens/doctor_selection_screen.dart';
import 'package:mediconnect/features/patient/screens/medical_records_screen.dart';
import 'package:mediconnect/features/payment/screens/payment_receipt_screen.dart';
import 'package:mediconnect/features/review/providers/review_provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:mediconnect/core/models/user_model.dart';
import 'package:mediconnect/features/patient/screens/doctor_list_screen.dart';
import 'package:mediconnect/features/patient/screens/doctor_profile_screen.dart';
import 'package:mediconnect/features/payment/screens/payment_details_screen.dart';
import 'package:mediconnect/features/payment/screens/payment_history_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core imports
import 'features/auth/providers/auth_provider.dart';
import 'core/services/api_service.dart';
import 'core/services/storage_service.dart';
import 'core/models/appointment_model.dart';
import 'core/models/medical_record_model.dart';

// Feature imports - Auth
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/splash_screen.dart';

// Feature imports - Doctor
import 'features/doctor/providers/doctor_provider.dart';
import 'features/doctor/screens/doctor_dashboard.dart';
import 'features/doctor/screens/doctor_appointments_screen.dart';

// Feature imports - Patient
import 'features/patient/providers/patient_provider.dart';
import 'features/patient/providers/doctor_list_provider.dart';
import 'features/patient/screens/patient_dashboard.dart';
import 'features/patient/screens/patient_appointments_screen.dart';

// Feature imports - Profile
import 'features/profile/providers/profile_provider.dart';
import 'features/profile/screens/profile_screen.dart';

// Feature imports - Appointment
import 'features/appointment/providers/appointment_provider.dart';

// Feature imports - Medical Records
import 'features/medical_records/providers/medical_records_provider.dart';
import 'features/medical_records/screens/medical_record_detail_screen.dart';

// Feature imports - Payment
import 'features/payment/providers/payment_provider.dart';
import 'features/payment/screens/payment_screen.dart';

// Feature imports - Notification
import 'features/notification/providers/notification_provider.dart';
import 'features/notification/screens/notification_screen.dart';

// Shared imports
import 'shared/constants/colors.dart';
import 'shared/constants/styles.dart';
import 'core/utils/session_helper.dart';

// Global navigator key for accessing context outside of build
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Helper getters for platform detection
bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;
bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize time zones
  tz_data.initializeTimeZones();

  // Initialize WebView platform if we're on mobile
  if (!kIsWeb) {
    if (isAndroid) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    } else if (isIOS) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    }
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize Services
  final storageService = StorageService(prefs);
  final apiService = ApiService();
  final authService = AuthService();

  // Get stored token if any
  final token = storageService.getToken();
  if (token != null) {
    apiService.setAuthToken(token);

    // Initialize socket with stored token
    final socketService = SocketService();
    socketService.initialize(token);
    print('App startup: Socket initialized with stored token');
  }

  // Log session information
  print(SessionHelper.getCurrentUTC());
  print(SessionHelper.getUserLogin());

  // Store session info in SharedPreferences
  await prefs.setString('last_login_time', SessionHelper.getCurrentUTC());
  await prefs.setString('last_user_login', SessionHelper.getUserLogin());

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        // Core services
        Provider<StorageService>(
          create: (_) => storageService,
        ),
        Provider<ApiService>(
          create: (_) => apiService,
        ),
        // Add AuthService
        Provider<AuthService>(
          create: (_) => authService,
        ),
        // Add UserService
        Provider<UserService>(
          create: (context) {
            final userService = UserService();
            // Set auth token if available
            final authProvider = context.read<AuthProvider>();
            if (authProvider.isAuthenticated && authProvider.token != null) {
              userService.setAuthToken(authProvider.token!);
            }
            return userService;
          },
        ),
        Provider<UserService>(
          create: (context) => UserService(
            apiService: context.read<ApiService>(),
          ),
        ),
        // Auth provider
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
        // Profile provider
        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (context) => ProfileProvider(
            apiService: context.read<ApiService>(),
            authProvider: context.read<AuthProvider>(),
          ),
          update: (context, auth, previous) =>
              previous ??
              ProfileProvider(
                apiService: context.read<ApiService>(),
                authProvider: auth,
              ),
        ),
        // Doctor provider
        ChangeNotifierProxyProvider<AuthProvider, DoctorProvider>(
          create: (context) => DoctorProvider(
            apiService: context.read<ApiService>(),
          ),
          update: (context, auth, previous) =>
              previous ??
              DoctorProvider(
                apiService: context.read<ApiService>(),
              ),
        ),
        // Patient provider
        ChangeNotifierProxyProvider<AuthProvider, PatientProvider>(
          create: (context) => PatientProvider(
            apiService: context.read<ApiService>(),
          ),
          update: (context, auth, previous) =>
              previous ??
              PatientProvider(
                apiService: context.read<ApiService>(),
              ),
        ),
        // Doctor list provider
        ChangeNotifierProvider(
          create: (context) => DoctorListProvider(
            apiService: context.read<ApiService>(),
          ),
        ),
        // Appointment provider
        ChangeNotifierProvider(
          create: (context) => AppointmentProvider(
            apiService: context.read<ApiService>(),
          ),
        ),
        // Add NotificationProvider
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(
            apiService: context.read<ApiService>(),
          ),
        ),
        // Add MedicalRecordsProvider
        ChangeNotifierProvider(
          create: (context) => MedicalRecordsProvider(
            apiService: context.read<ApiService>(),
          ),
        ),
        // Add PaymentProvider
        ChangeNotifierProvider(
          create: (context) => PaymentProvider(
            apiService: context.read<ApiService>(),
          ),
        ),
        // Add ReviewProvider
        ChangeNotifierProvider(
          create: (context) => ReviewProvider(
            apiService: context.read<ApiService>(),
          ),
        ),
        // Add CalendarProvider
        ChangeNotifierProvider(
          create: (context) => CalendarProvider(apiService: apiService),
        ),
        // Add TodoProvider
        ChangeNotifierProvider(
          create: (context) => TodoProvider(apiService: apiService),
        ),
        // Add MedicationReminderProvider
        ChangeNotifierProvider(
          create: (context) => MedicationReminderProvider(),
        ),
        // Add SocketService
        Provider<SocketService>(
          create: (_) => SocketService(),
        ),
        // Add MessageService
        Provider<MessageService>(
          create: (context) => MessageService(
            apiService: context.read<ApiService>(),
          ),
        ),
        Provider<HealthAIService>(
          create: (context) {
            final healthService = HealthAIService();
            // Set auth token if available
            final authProvider = context.read<AuthProvider>();
            if (authProvider.isAuthenticated && authProvider.token != null) {
              healthService.setAuthToken(authProvider.token!);
            }
            return healthService;
          },
        ),
        // Add HealthAIProvider
        ChangeNotifierProvider(
          create: (context) => HealthAIProvider(
            context.read<HealthAIService>(),
          ),
        ),
        // Add MessageProvider
        ChangeNotifierProvider(
          create: (context) => MessageProvider(
            messageService: context.read<MessageService>(),
            socketService: context.read<SocketService>(),
            authService: context.read<AuthService>(),
          ),
        ),
        // Add conversationProvider
        ChangeNotifierProvider(
          create: (context) => ConversationProvider(
            messageService: context.read<MessageService>(),
            authService: context.read<AuthService>(),
            socketService: context.read<SocketService>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Schedule the socket initialization for after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSocketService();
    });
  }

  void _initializeSocketService() {
    try {
      // Access providers directly from the current context
      final socketService = Provider.of<SocketService>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);
      final messageService =
          Provider.of<MessageService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      // Initialize services if user is authenticated
      if (authProvider.isAuthenticated && authProvider.token != null) {
        print(
            'Initializing services with token: ${authProvider.token!.substring(0, 10)}...');

        // Set the auth token on all relevant services
        apiService.setAuthToken(authProvider.token!);
        messageService.setAuthToken(authProvider.token!);
        authService.setAuthToken(authProvider.token!);

        // Set user ID if available
        if (authProvider.user != null) {
          authService.setCurrentUserId(authProvider.user!.id);
        }

        // Initialize socket
        socketService.initialize(authProvider.token!);
      }

      // Listen for auth changes to reconnect socket if needed
      authProvider.addListener(() {
        if (authProvider.isAuthenticated && authProvider.token != null) {
          print('Auth changed: Reconnecting socket');

          // Update token for all services
          apiService.setAuthToken(authProvider.token!);
          messageService.setAuthToken(authProvider.token!);
          authService.setAuthToken(authProvider.token!);

          // Update user ID
          if (authProvider.user != null) {
            authService.setCurrentUserId(authProvider.user!.id);
          }

          // Initialize socket
          socketService.initialize(authProvider.token!);
        } else {
          print('Auth changed: Disconnecting socket');
          socketService.disconnect();
        }
      });

      // Initialize other providers
      _initializeProviders();
    } catch (e) {
      print('Error initializing socket service: $e');
    }
  }

  void _initializeProviders() {
    try {
      // Initialize MessageProvider
      final messageProvider =
          Provider.of<MessageProvider>(context, listen: false);
      messageProvider.initialize().catchError((e) {
        print('Error initializing MessageProvider: $e');
      });

      // Initialize ConversationProvider
      final conversationProvider =
          Provider.of<ConversationProvider>(context, listen: false);
      conversationProvider.initialize().catchError((e) {
        print('Error initializing ConversationProvider: $e');
      });
    } catch (e) {
      print('Error in _initializeProviders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MediConnect',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const SplashScreen(),
      routes: {
        // Auth routes
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),

        // Shared routes
        '/profile': (context) => const ProfileScreen(
              userData: {},
            ),
        '/notifications': (context) => const NotificationScreen(),

        // Patient routes
        '/patient/doctors': (context) => const DoctorsListScreen(),
        '/patient/appointments': (context) => const PatientAppointmentsScreen(),
        '/patient/dashboard': (context) => const PatientDashboard(),
        '/medical-records': (context) => const PatientMedicalRecordsScreen(),

        // Doctor routes
        '/doctor/dashboard': (context) => const DoctorDashboard(),
        '/doctor/appointments': (context) => const DoctorAppointmentsScreen(),
        '/doctor/patients': (context) => const PatientListScreen(),
        '/doctor/patient-details': (context) {
          final patientId =
              ModalRoute.of(context)!.settings.arguments as String;
          return PatientProfileScreen(patientId: patientId);
        },

        // Payment routes (that don't need arguments)
        '/payment/history': (context) => const PaymentHistoryScreen(),

        // Add calendar routes
        '/doctor/calendar': (context) => const DoctorCalendarScreen(),
        '/doctor/calendar/working-hours': (context) =>
            const WorkingHoursSettingsScreen(),

        // Health AI routes
        '/health-assistant': (context) => const HealthSessionsScreen(),

        // Add message routes
        '/messages': (context) => ChatListScreen(),

        '/messages/chat': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return ChatDetailScreen(
            conversationId: args['conversationId'],
            otherUser: args['otherUser'],
          );
        },
        '/messages/doctor-selection': (context) {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          final userRole = authProvider.user?.role.toLowerCase() ?? '';

          if (userRole == 'doctor') {
            // For doctors - show contacts with both doctors and patients tabs
            return DoctorContactsScreen();
          } else {
            // For patients - show only doctor selection
            return DoctorSelectionScreen();
          }
        },
      },
      onGenerateRoute: (settings) {
        // Handle socket test
        // if (settings.name == SocketTestScreen.routeName) {
        //   return MaterialPageRoute(
        //     builder: (_) => SocketTestScreen(),
        //   );
        // }
        // Handle messages screen
        if (settings.name == '/messages/chat') {
          final args = settings.arguments;
          if (args is Map<String, dynamic>) {
            return MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                conversationId: args['conversationId'],
                otherUser: args['otherUser'],
              ),
              settings: settings,
            );
          }
          return _errorRoute('Invalid chat parameters');
        }

        // Handle doctor profile
        if (settings.name == '/doctor/profile') {
          final args = settings.arguments;
          if (args is User) {
            return MaterialPageRoute(
              builder: (context) => DoctorProfileScreen(doctor: args),
              settings: settings,
            );
          }
          // Handle invalid arguments
          return _errorRoute('Invalid doctor profile data');
        }

        // Handle patient details
        if (settings.name == '/doctor/patient-details') {
          final args = settings.arguments;
          if (args is String) {
            return MaterialPageRoute(
              builder: (context) => PatientProfileScreen(patientId: args),
              settings: settings,
            );
          }
          return _errorRoute('Invalid patient ID');
        }

        // Handle payment screen
        if (settings.name == '/payment') {
          final args = settings.arguments;
          if (args is Appointment) {
            return MaterialPageRoute(
              builder: (context) => PaymentScreen(appointment: args),
              settings: settings,
            );
          }
          return _errorRoute('Invalid payment data');
        }

        // For payment details screen
        if (settings.name == '/payment/details') {
          final args = settings.arguments;
          if (args is String) {
            return MaterialPageRoute(
              builder: (context) => PaymentDetailsScreen(paymentId: args),
              settings: settings,
            );
          }
          return _errorRoute('Invalid payment ID');
        }

        // Handle payment receipt
        if (settings.name == '/payment/receipt') {
          final args = settings.arguments as Map<String, String>;
          return MaterialPageRoute(
            builder: (context) => PaymentReceiptScreen(
              paymentId: args['paymentId']!,
              paymentReference: args['paymentReference']!,
            ),
            settings: settings,
          );
        }

        // Handle medical record detail
        if (settings.name == '/medical-record/detail') {
          final args = settings.arguments;
          if (args is Map<String, dynamic>) {
            // New format with recordId
            return MaterialPageRoute(
              builder: (context) => MedicalRecordDetailScreen(
                recordId: args['recordId'],
                isDoctorView: args['isDoctorView'] ?? false,
                patientName: args['patientName'],
              ),
              settings: settings,
            );
          } else if (args is MedicalRecord) {
            // Legacy format with direct record object
            // This maintains backward compatibility
            return MaterialPageRoute(
              builder: (context) => MedicalRecordDetailScreen(
                recordId: args.id,
                isDoctorView: false,
              ),
              settings: settings,
            );
          }
          return _errorRoute('Invalid medical record data');
        }

        // Handle medical record detail
        if (settings.name == '/medical-record/detail') {
          final args = settings.arguments;
          if (args is Map<String, dynamic>) {
            // New format with recordId
            return MaterialPageRoute(
              builder: (context) => MedicalRecordDetailScreen(
                recordId: args['recordId'],
                isDoctorView: args['isDoctorView'] ?? false,
                patientName: args['patientName'],
              ),
              settings: settings,
            );
          } else if (args is String) {
            // Simple recordId string
            return MaterialPageRoute(
              builder: (context) => MedicalRecordDetailScreen(
                recordId: args,
                isDoctorView: false,
              ),
              settings: settings,
            );
          } else if (args == null) {
            // Default to the medical records list screen if no arguments
            return MaterialPageRoute(
              builder: (context) => const PatientMedicalRecordsScreen(),
              settings: settings,
            );
          }
          return _errorRoute('Invalid medical record data');
        }

        return null;
      },
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.0)),
            child: child!,
          ),
        );
      },
    );
  }

// Helper method for error routes
  Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Text(message),
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppStyles.heading2.copyWith(
          color: AppColors.textLight,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textLight,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppColors.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 100), // Added bottom margin
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentTextStyle: AppStyles.bodyText2.copyWith(
          color: AppColors.textLight,
        ),
      ),
    );
  }
}
