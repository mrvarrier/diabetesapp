// File: lib/presentation/screens/auth/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/constants.dart';
import '../../../core/utils/app_colors.dart';
import '../../../domain/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animation
    _animationController.forward();

    // Check auth state after animation
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Allow animation to play for a moment before navigating
    await Future.delayed(const Duration(seconds: 2));

    // Check if mounted before proceeding
    if (!mounted) return;

    // Get auth provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Navigate based on auth state
    switch (authProvider.status) {
      case AuthStatus.authenticated:
      // Check if onboarding is completed
        if (authProvider.user?.isOnboardingCompleted == true) {
          Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
        } else {
          Navigator.of(context).pushReplacementNamed(AppConstants.onboardingRoute);
        }
        break;
      case AuthStatus.unauthenticated:
        Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
        break;
      case AuthStatus.uninitialized:
      // Wait a bit longer and check again
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _checkAuthState();
        }
        break;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildLogo(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // App logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            Icons.medical_services_rounded,
            size: 64,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        // App name
        Text(
          AppConstants.appName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        // App tagline
        const Text(
          "Learn, Manage, Thrive",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 48),
        // Loading indicator
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
        ),
      ],
    );
  }
}