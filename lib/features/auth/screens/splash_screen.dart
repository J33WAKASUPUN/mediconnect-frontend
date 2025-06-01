import 'package:flutter/material.dart';
import 'package:mediconnect/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _indicatorOpacityAnimation;

  @override
  void initState() {
    super.initState();
    
    // Set up animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    // Logo animations
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    
    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    
    // Text animation
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.7, curve: Curves.easeIn),
      ),
    );
    
    // Indicator animation
    _indicatorOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 0.9, curve: Curves.easeIn),
      ),
    );
    
    _controller.forward();
    
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final route = authProvider.getInitialRoute();
    
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                // Decorative elements
                Positioned(
                  top: size.height * 0.05,
                  right: -size.width * 0.2,
                  child: Opacity(
                    opacity: 0.08,
                    child: Icon(
                      Icons.healing,
                      size: size.width * 0.7,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -size.height * 0.1,
                  left: -size.width * 0.2,
                  child: Opacity(
                    opacity: 0.06,
                    child: Icon(
                      Icons.medical_services,
                      size: size.width * 0.8,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                
                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with animations
                      FadeTransition(
                        opacity: _logoOpacityAnimation,
                        child: ScaleTransition(
                          scale: _logoScaleAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.medical_services,
                              size: 70,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // App name
                      FadeTransition(
                        opacity: _textOpacityAnimation,
                        child: Column(
                          children: [
                            Text(
                              'MediConnect',
                              style: AppStyles.heading1.copyWith(
                                color: AppColors.textLight,
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Healthcare at your fingertips',
                                style: AppStyles.subtitle2.copyWith(
                                  color: AppColors.textLight,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // Loading indicator
                      FadeTransition(
                        opacity: _indicatorOpacityAnimation,
                        child: Column(
                          children: [
                            SizedBox(
                              width: 45,
                              height: 45,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Text(
                            //   'Loading...',
                            //   style: AppStyles.bodyText2.copyWith(
                            //     color: AppColors.textLight.withOpacity(0.8),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Version info
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _textOpacityAnimation,
                    child: Text(
                      'v2.5.0',
                      textAlign: TextAlign.center,
                      style: AppStyles.caption.copyWith(
                        color: AppColors.textLight.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}