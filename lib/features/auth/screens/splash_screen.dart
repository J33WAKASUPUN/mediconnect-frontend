import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final route = authProvider.getInitialRoute();
    
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo or Icon here
            const Icon(
              Icons.medical_services,
              size: 80,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 24),
            Text(
              'MediConnect',
              style: AppStyles.heading1.copyWith(
                color: AppColors.textLight,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}