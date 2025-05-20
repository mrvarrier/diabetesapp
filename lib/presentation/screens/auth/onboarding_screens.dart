// File: lib/presentation/screens/auth/onboarding_screens.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/constants.dart';
import '../../../core/utils/app_colors.dart';
import '../../../domain/providers/auth_provider.dart';

class OnboardingScreens extends StatefulWidget {
  const OnboardingScreens({Key? key}) : super(key: key);

  @override
  State<OnboardingScreens> createState() => _OnboardingScreensState();
}

class _OnboardingScreensState extends State<OnboardingScreens> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to DiabetesEdu',
      description: 'Your personalized learning companion for diabetes education and management.',
      image: 'assets/images/onboarding_1.png', // You'll need to add these assets
      iconData: Icons.health_and_safety,
      backgroundColor: AppColors.primaryColor,
    ),
    OnboardingPage(
      title: 'Learn at Your Pace',
      description: 'Watch videos, read slides, and take quizzes to improve your diabetes knowledge.',
      image: 'assets/images/onboarding_2.png',
      iconData: Icons.menu_book,
      backgroundColor: AppColors.secondaryColor,
    ),
    OnboardingPage(
      title: 'Track Your Progress',
      description: 'Earn points, unlock achievements, and monitor your learning journey.',
      image: 'assets/images/onboarding_3.png',
      iconData: Icons.bar_chart,
      backgroundColor: AppColors.accentColor,
    ),
    OnboardingPage(
      title: 'Daily Reminders',
      description: 'Set reminders to maintain your learning streak and build healthy habits.',
      image: 'assets/images/onboarding_4.png',
      iconData: Icons.notifications_active,
      backgroundColor: AppColors.info,
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _isLastPage = page == _pages.length - 1;
    });
  }

  void _nextPage() {
    if (_isLastPage) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _pageController.jumpToPage(_pages.length - 1);
  }

  Future<void> _completeOnboarding() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Complete onboarding
    final success = await authProvider.completeOnboarding();

    // Dismiss loading indicator
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
    } else if (mounted) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to complete onboarding'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page view
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),

          // Skip button
          if (!_isLastPage)
            Positioned(
              top: 50,
              right: 20,
              child: TextButton(
                onPressed: _skipOnboarding,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Bottom navigation
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Page indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                        (index) => _buildDotIndicator(index),
                  ),
                ),
                const SizedBox(height: 30),
                // Next/Get Started button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _pages[_currentPage].backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _isLastPage ? 'Get Started' : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Container(
      color: page.backgroundColor,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Image or icon placeholder
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                page.iconData,
                size: 100,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            // Title and description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  Text(
                    page.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    page.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildDotIndicator(int index) {
    final isActive = index == _currentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;
  final IconData iconData;
  final Color backgroundColor;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.iconData,
    required this.backgroundColor,
  });
}