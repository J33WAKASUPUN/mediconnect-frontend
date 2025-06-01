import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/styled_alert_dialog.dart';
import '../widgets/role_toggle.dart';

@JS('saveCredentials')
external void _jsSaveCredentials(String username, String password);

@JS('saveAuthToken')
external void _jsSaveAuthToken(String token);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'patient';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => StyledAlertDialog(
        title: 'Error',
        message: message,
        buttonText: 'Try Again',
        icon: Icons.error_outline,
        iconColor: Colors.red,
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => StyledAlertDialog(
        title: 'Success',
        message: message,
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
        onPressed: () {
          Navigator.pop(context);
          // Navigate based on role
          Navigator.of(context).pushReplacementNamed(
            _selectedRole == 'patient' ? '/patient/dashboard' : '/doctor/dashboard',
          );
        },
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      // Show validation error popup if form is not valid
      _showErrorDialog('Please fill all the required fields correctly.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // For web, try to save credentials for browser
      if (kIsWeb) {
        try {
          _jsSaveCredentials(
            _emailController.text.trim(),
            _passwordController.text,
          );
        } catch (e) {
          print("Error saving credentials: $e");
          // Continue with login even if credential saving fails
        }
      }

      // Login using AuthProvider
      final response = await context.read<AuthProvider>().login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: _selectedRole,
          );

      // For web, save auth token in localStorage
      if (kIsWeb && response['token'] != null) {
        try {
          _jsSaveAuthToken(response['token']);
        } catch (e) {
          print("Error saving auth token: $e");
        }
      }

      if (!mounted) return;

      // Show success dialog
      _showSuccessDialog('Login successful! Welcome back.');
      
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Logging in...',
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  // Logo
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.medical_services,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Welcome text
                  Text(
                    'Welcome Back',
                    style: AppStyles.heading1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue to MediConnect',
                    style: AppStyles.bodyText2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  // Role toggle
                  RoleToggle(
                    selectedRole: _selectedRole,
                    onRoleChanged: (role) => setState(() => _selectedRole = role),
                  ),
                  const SizedBox(height: 32),
                  // Email field
                  CustomTextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Password field
                  CustomTextField(
                    label: 'Password',
                    controller: _passwordController,
                    isPassword: true,
                    prefixIcon: Icons.lock,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Login button
                  CustomButton(
                    text: 'Login',
                    onPressed: _login,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),
                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        child: Text(
                          "Create one",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}