import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediconnect/core/models/user_model.dart';
import 'package:mediconnect/features/patient/screens/doctor_list_screen.dart';
import 'package:mediconnect/features/patient/screens/doctor_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/auth_provider.dart';
import 'core/services/api_service.dart';
import 'core/services/storage_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/doctor/providers/doctor_provider.dart';
import 'features/doctor/screens/doctor_dashboard.dart';
import 'features/doctor/screens/doctor_appointments_screen.dart';
import 'features/patient/providers/patient_provider.dart';
import 'features/patient/providers/doctor_list_provider.dart';
import 'features/patient/screens/patient_dashboard.dart';
import 'features/patient/screens/patient_appointments_screen.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/appointment/providers/appointment_provider.dart';
import 'features/medical_records/screens/medical_record_detail_screen.dart';
import 'features/payment/screens/payment_screen.dart';
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
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (context) => ProfileProvider(
            apiService: context.read<ApiService>(),
            authProvider: context.read<AuthProvider>(),
          ),
          update: (context, auth, previous) => previous ?? ProfileProvider(
            apiService: context.read<ApiService>(),
            authProvider: auth,
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, DoctorProvider>(
          create: (context) => DoctorProvider(
            apiService: context.read<ApiService>(),
          ),
          update: (context, auth, previous) => previous ?? DoctorProvider(
            apiService: context.read<ApiService>(),
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PatientProvider>(
          create: (context) => PatientProvider(
            apiService: context.read<ApiService>(),
          ),
          update: (context, auth, previous) => previous ?? PatientProvider(
            apiService: context.read<ApiService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => DoctorListProvider(
            apiService: context.read<ApiService>(),
          ),
        ),
        // Add AppointmentProvider - THIS WAS MISSING
        ChangeNotifierProvider(
          create: (context) => AppointmentProvider(
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
      onGenerateRoute: (settings) {
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
        return null;
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/patient/dashboard': (context) => const PatientDashboard(),
        '/doctor/dashboard': (context) => const DoctorDashboard(),
        '/profile': (context) => const ProfileScreen(),
        '/patient/doctors': (context) => const DoctorsListScreen(),
        // Added missing routes
        '/patient/appointments': (context) => const PatientAppointmentsScreen(),
        '/doctor/appointments': (context) => const DoctorAppointmentsScreen(),
        // Add other routes as needed
      },
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
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