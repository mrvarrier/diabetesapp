// File: lib/presentation/screens/auth/register_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/constants.dart';
import '../../../core/utils/app_colors.dart';
import '../../../domain/providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  // User profile info
  int _age = 30;
  String _gender = 'Male';
  String _diabetesType = AppConstants.diabetesType2;
  String _treatmentMethod = AppConstants.treatmentLifestyle;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  final Map<String, String> _diabetesTypeOptions = {
    AppConstants.diabetesType1: 'Type 1 Diabetes',
    AppConstants.diabetesType2: 'Type 2 Diabetes',
    AppConstants.diabetesGestational: 'Gestational Diabetes',
    AppConstants.diabetesPre: 'Prediabetes',
  };

  final Map<String, String> _treatmentMethodOptions = {
    AppConstants.treatmentInsulin: 'Insulin Injections',
    AppConstants.treatmentPump: 'Insulin Pump',
    AppConstants.treatmentMedication: 'Oral Medication',
    AppConstants.treatmentLifestyle: 'Diet & Exercise',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_validateBasicInfo()) {
        setState(() {
          _currentStep = 1;
        });
      }
    } else if (_currentStep == 1) {
      if (_validateMedicalInfo()) {
        _register();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _validateBasicInfo() {
    // Validate name, email, and password
    return _formKey.currentState?.validate() ?? false;
  }

  bool _validateMedicalInfo() {
    // Age validation
    if (_age < 18 || _age > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid age between 18 and 100'),
          backgroundColor: AppColors.error,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate() && _validateMedicalInfo()) {
      // Hide keyboard
      FocusScope.of(context).unfocus();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        age: _age,
        gender: _gender,
        diabetesType: _diabetesType,
        treatmentMethod: _treatmentMethod,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed(AppConstants.onboardingRoute);
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),
              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 2,
                  backgroundColor: AppColors.progressBarBackground,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 24),
              // Step indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of 2',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _currentStep == 0 ? 'Basic Information' : 'Medical Profile',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Error message
              if (authProvider.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authProvider.error!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: _currentStep == 0
                      ? _buildBasicInfoStep()
                      : _buildMedicalInfoStep(),
                ),
              ),
              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: authProvider.isLoading ? null : _previousStep,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Previous'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _nextStep,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                            : Text(_currentStep == 0 ? 'Next' : 'Register'),
                      ),
                    ),
                  ],
                ),
              ),
              // Sign in link
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: GestureDetector(
                  onTap: _navigateToLogin,
                  child: RichText(
                    text: const TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appName,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Create your account',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field
        const Text(
          'Full Name',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            if (value.trim().split(' ').length < 2) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Email field
        const Text(
          'Email Address',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Enter your email address',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Password field
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_passwordVisible,
          decoration: InputDecoration(
            hintText: 'Create a password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Confirm password field
        const Text(
          'Confirm Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_confirmPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Confirm your password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _confirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _confirmPasswordVisible = !_confirmPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMedicalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Age field
        const Text(
          'Age',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Slider(
                  value: _age.toDouble(),
                  min: 18,
                  max: 100,
                  divisions: 82,
                  label: _age.toString(),
                  onChanged: (value) {
                    setState(() {
                      _age = value.round();
                    });
                  },
                ),
              ),
              Container(
                width: 48,
                alignment: Alignment.center,
                child: Text(
                  _age.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Gender field
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: _genderOptions.map((gender) {
              return RadioListTile<String>(
                title: Text(gender),
                value: gender,
                groupValue: _gender,
                onChanged: (value) {
                  setState(() {
                    _gender = value!;
                  });
                },
                activeColor: AppColors.primaryColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                dense: true,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Diabetes type field
        const Text(
          'Diabetes Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: _diabetesTypeOptions.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: _diabetesType,
                onChanged: (value) {
                  setState(() {
                    _diabetesType = value!;
                  });
                },
                activeColor: AppColors.primaryColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                dense: true,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Treatment method field
        const Text(
          'Treatment Method',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: _treatmentMethodOptions.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: _treatmentMethod,
                onChanged: (value) {
                  setState(() {
                    _treatmentMethod = value!;
                  });
                },
                activeColor: AppColors.primaryColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                dense: true,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Privacy disclaimer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Privacy Note',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your medical information will be used to customize your educational content. We value your privacy and handle your data securely.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}