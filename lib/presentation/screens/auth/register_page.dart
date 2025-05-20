import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_service.dart';
import '../../../services/analytics_service.dart';
import '../../../constants/string_constants.dart';
import '../../../navigation/app_router.dart';
import '../../../screens/widgets/custom_text_field.dart';
import '../../../screens/widgets/custom_button.dart';
import '../../../screens/widgets/custom_dropdown.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  // Form field values
  String _selectedGender = 'Male';
  String _selectedDiabetesType = 'Type 2';
  String _selectedTreatmentMethod = 'Oral Medication';

  // Lists for dropdown options
  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _diabetesTypeOptions = ['Type 1', 'Type 2', 'Gestational', 'Prediabetes', 'Other'];
  final List<String> _treatmentMethodOptions = ['Insulin', 'Oral Medication', 'Insulin Pump', 'Diet & Exercise'];

  // Page controller for multi-step form
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _stepTitles = [
    'Account Information',
    'Personal Information',
    'Medical Information',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _ageController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // For first page, validate email and password before proceeding
    if (_currentPage == 0) {
      if (_emailController.text.isEmpty ||
          !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text) ||
          _passwordController.text.isEmpty ||
          _passwordController.text.length < 6 ||
          _passwordController.text != _confirmPasswordController.text) {
        // Form validation failed
        return;
      }
    }

    // For second page, validate name and age before proceeding
    if (_currentPage == 1) {
      if (_fullNameController.text.isEmpty ||
          _ageController.text.isEmpty ||
          int.tryParse(_ageController.text) == null) {
        // Form validation failed
        return;
      }
    }

    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
      });
    } else {
      // On last page, submit the form
      _register();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage--;
      });
    }
  }

  Future<void> _register() async {
    // Validate entire form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Register with email and password
      await authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _fullNameController.text.trim(),
        int.parse(_ageController.text.trim()),
        _selectedGender,
        _selectedDiabetesType,
        _selectedTreatmentMethod,
      );

      // Set user properties for analytics
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      await analyticsService.setUserProperties(
        diabetesType: _selectedDiabetesType,
        treatmentMethod: _selectedTreatmentMethod,
        age: int.parse(_ageController.text.trim()),
      );

      // Log session start
      await analyticsService.logSessionStart();

      // Navigate to onboarding
      AppRouter.navigateToAndRemoveUntil('/onboarding');
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        default:
          message = 'An error occurred during registration.';
      }

      setState(() {
        _errorMessage = message;
        // Go back to first page if email error
        if (e.code == 'email-already-in-use' || e.code == 'invalid-email') {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          _currentPage = 0;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
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
      appBar: AppBar(
        title: Text(StringConstants.register),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentPage > 0) {
              _previousPage();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stepper indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(
                  3,
                      (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Step title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _stepTitles[_currentPage],
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Error message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Disable swiping
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    // Page 1: Account Information
                    _buildAccountInfoPage(),

                    // Page 2: Personal Information
                    _buildPersonalInfoPage(),

                    // Page 3: Medical Information
                    _buildMedicalInfoPage(),
                  ],
                ),
              ),
            ),

            // Bottom navigation
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentPage > 0)
                    const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: _currentPage < 2 ? 'Next' : 'Create Account',
                      isLoading: _isLoading,
                      onPressed: _nextPage,
                    ),
                  ),
                ],
              ),
            ),

            // Sign in link
            if (_currentPage == 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: StringConstants.alreadyHaveAccount,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    children: [
                      TextSpan(
                        text: StringConstants.signIn,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).pop();
                          },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Page 1: Account Information
  Widget _buildAccountInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          CustomTextField(
            controller: _emailController,
            labelText: StringConstants.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return StringConstants.emailRequired;
              }

              // Basic email validation
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return StringConstants.validEmailRequired;
              }

              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password field
          CustomTextField(
            controller: _passwordController,
            labelText: StringConstants.password,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return StringConstants.passwordRequired;
              }

              if (value.length < 6) {
                return StringConstants.passwordLength;
              }

              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm password field
          CustomTextField(
            controller: _confirmPasswordController,
            labelText: StringConstants.confirmPassword,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return StringConstants.passwordRequired;
              }

              if (value != _passwordController.text) {
                return StringConstants.passwordMatch;
              }

              return null;
            },
          ),
          const SizedBox(height: 24),

          // Password requirements
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password Requirements:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _buildPasswordRequirement(
                  'At least 6 characters',
                  _passwordController.text.length >= 6,
                ),
                const SizedBox(height: 4),
                _buildPasswordRequirement(
                  'Passwords match',
                  _passwordController.text.isNotEmpty &&
                      _passwordController.text == _confirmPasswordController.text,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Page 2: Personal Information
  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full name field
          CustomTextField(
            controller: _fullNameController,
            labelText: StringConstants.fullName,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return StringConstants.nameRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Age field
          CustomTextField(
            controller: _ageController,
            labelText: StringConstants.age,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.cake_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return StringConstants.fieldRequired;
              }

              final age = int.tryParse(value);
              if (age == null) {
                return 'Please enter a valid age';
              }

              if (age < 1 || age > 120) {
                return 'Please enter a valid age between 1 and 120';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),

          // Gender dropdown
          CustomDropdown(
            label: StringConstants.gender,
            value: _selectedGender,
            items: _genderOptions,
            prefixIcon: Icons.people_outline,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedGender = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // Page 3: Medical Information
  Widget _buildMedicalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Diabetes type dropdown
          CustomDropdown(
            label: StringConstants.diabetesType,
            value: _selectedDiabetesType,
            items: _diabetesTypeOptions,
            prefixIcon: Icons.medical_information_outlined,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedDiabetesType = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Treatment method dropdown
          CustomDropdown(
            label: StringConstants.treatmentMethod,
            value: _selectedTreatmentMethod,
            items: _treatmentMethodOptions,
            prefixIcon: Icons.healing_outlined,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedTreatmentMethod = value;
                });
              }
            },
          ),
          const SizedBox(height: 24),

          // Information text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Why we ask for this information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your diabetes type and treatment method help us personalize your learning experience with relevant content tailored to your specific needs.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This information is kept secure and is only used to customize your education plan.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Helper for password requirements
  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: isMet
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isMet
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}