// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediconnect/features/doctor/screens/patient_profile_screen.dart';
import 'package:mediconnect/features/doctor/screens/patient_list_screen.dart';
import 'package:mediconnect/features/patient/screens/medical_records_screen.dart';
import 'package:mediconnect/features/payment/screens/payment_receipt_screen.dart';
import 'package:mediconnect/features/review/providers/review_provider.dart';
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
import 'core/providers/auth_provider.dart';
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

// Helper getters for platform detection
bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;
bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediConnect',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const SplashScreen(),
      routes: {
        // Auth routes
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),

        // Shared routes
        '/profile': (context) => const ProfileScreen(),
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
      },
      onGenerateRoute: (settings) {
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
