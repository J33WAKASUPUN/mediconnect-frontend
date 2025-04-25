import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediconnect/core/models/user_model.dart';
import 'package:mediconnect/features/patient/screens/doctor_list_screen.dart';
import 'package:mediconnect/features/patient/screens/doctor_profile_screen.dart';
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

class SessionInfo {
  static String getCurrentUTC() {
    final now = DateTime.now().toUtc();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  static String getUserLogin() {
    return 'J33WAKASUPUN';
  }

  static String getFormattedCurrentTime() {
    return 'Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): ${getCurrentUTC()}';
  }

  static String getFormattedUserLogin() {
    return 'Current User\'s Login: ${getUserLogin()}';
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize Services
  final storageService = StorageService(prefs);
  final apiService = ApiService();

  // Log session information
  print(SessionInfo.getFormattedCurrentTime());
  print(SessionInfo.getFormattedUserLogin());

  // Store session info in SharedPreferences
  await prefs.setString('last_login_time', SessionInfo.getCurrentUTC());
  await prefs.setString('last_user_login', SessionInfo.getUserLogin());

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
        // Add SessionInfo as a provider to make it accessible throughout the app
        Provider<SessionInfo>(
          create: (_) => SessionInfo(),
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

        // Dashboard routes
        '/patient/dashboard': (context) => const PatientDashboard(),
        '/doctor/dashboard': (context) => const DoctorDashboard(),

        // Shared routes
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationScreen(),

        // Patient routes
        '/patient/doctors': (context) => const DoctorsListScreen(),
        '/patient/appointments': (context) => const PatientAppointmentsScreen(),

        // Doctor routes
        '/doctor/appointments': (context) => const DoctorAppointmentsScreen(),
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
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Error'),
              ),
              body: const Center(
                child: Text('Invalid doctor profile data'),
              ),
            ),
          );
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
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Error'),
              ),
              body: const Center(
                child: Text('Invalid payment data'),
              ),
            ),
          );
        }

        // Handle medical record detail
        if (settings.name == '/medical-record/detail') {
          final args = settings.arguments;
          if (args is MedicalRecord) {
            return MaterialPageRoute(
              builder: (context) => MedicalRecordDetailScreen(record: args),
              settings: settings,
            );
          }
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Error'),
              ),
              body: const Center(
                child: Text('Invalid medical record data'),
              ),
            ),
          );
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
