import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/analytics_service.dart';
import '../../../constants/string_constants.dart';
import '../../../navigation/app_router.dart';
import '../../../screens/widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;
  bool _isLoading = false;

  // Onboarding data
  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'Welcome to DiabetesBuddy',
      'description': 'Your personalized diabetes education companion. Learn at your own pace and build healthy habits.',
      'image': 'assets/images/onboarding_welcome.png',
    },
    {
      'title': 'Learn Through Videos & Slides',
      'description': 'Watch engaging educational videos and interactive slides tailored to your diabetes type.',
      'image': 'assets/images/onboarding_learn.png',
    },
    {
      'title': 'Test Your Knowledge',
      'description': 'Take quizzes to reinforce your learning and track your progress over time.',
      'image': 'assets/images/onboarding_quiz.png',
    },
    {
      'title': 'Earn Points & Achievements',
      'description': 'Stay motivated with gamification features like points, streaks, and achievements.',
      'image': 'assets/images/onboarding_achievements.png',
    },
    {
      'title': 'Track Your Progress',
      'description': 'Monitor your learning journey with detailed progress reports and statistics.',
      'image': 'assets/images/onboarding_progress.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _isLastPage = _currentPage == _onboardingData.length - 1;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _pageController.animateToPage(
      _onboardingData.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Mark onboarding as complete
      await authService.completeOnboarding();

      // Log onboarding completion
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      analyticsService.logFeatureUse('onboarding_complete');

      // Navigate to home
      AppRouter.navigateToAndRemoveUntil('/home');
    } catch (e) {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing onboarding: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (!_isLastPage)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, right: 16),
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      StringConstants.skip,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // Onboarding content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                    _isLastPage = _currentPage == _onboardingData.length - 1;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(
                    _onboardingData[index]['title'],
                    _onboardingData[index]['description'],
                    _onboardingData[index]['image'],
                  );
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _onboardingData.length,
                      (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: CustomButton(
                text: _isLastPage ? StringConstants.getStarted : StringConstants.next,
                isLoading: _isLoading,
                onPressed: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(String title, String description, String imagePath) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image
          Expanded(
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}