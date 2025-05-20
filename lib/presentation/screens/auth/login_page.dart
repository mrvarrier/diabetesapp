// File: lib/presentation/screens/auth/login_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/constants.dart';
import '../../../core/utils/app_colors.dart';
import '../../../domain/providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      // Hide keyboard
      FocusScope.of(context).unfocus();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        // Check if onboarding is completed
        if (authProvider.user?.isOnboardingCompleted == true) {
          Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
        } else {
          Navigator.of(context).pushReplacementNamed(AppConstants.onboardingRoute);
        }
      }
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).pushReplacementNamed(AppConstants.registerRoute);
  }

  void _showForgotPasswordDialog() {
    final forgotEmailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your email and we\'ll send you a link to reset your password.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: forgotEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email address',
                  prefixIcon: Icon(Icons.email_outlined),
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop();

                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sending password reset email...'),
                    duration: Duration(seconds: 2),
                  ),
                );

                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final success = await authProvider.resetPassword(
                  forgotEmailController.text.trim(),
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Password reset email sent! Check your inbox.'
                            : authProvider.error ?? 'Failed to send reset email. Try again later.',
                      ),
                      backgroundColor: success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // App logo and title
                  _buildHeader(),
                  const SizedBox(height: 48),
                  // Error message
                  if (authProvider.error != null)
                    _buildErrorMessage(authProvider.error!),
                  // Email field
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  // Password field
                  _buildPasswordField(),
                  const SizedBox(height: 16),
                  // Remember me and forgot password
                  _buildRememberMeAndForgotPassword(),
                  const SizedBox(height: 24),
                  // Login button
                  _buildLoginButton(authProvider.isLoading),
                  const SizedBox(height: 24),
                  // Divider
                  _buildDivider(),
                  const SizedBox(height: 24),
                  // Register link
                  _buildRegisterLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              AppConstants.appName,
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Welcome Back!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign in to continue your diabetes education journey',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String errorMessage) {
    return Container(
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
              errorMessage,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
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
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_passwordVisible,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
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
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    return Row(
      children: [
        // Remember me
        Expanded(
          child: Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Remember me',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Forgot password
        GestureDetector(
          onTap: _showForgotPasswordDialog,
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        )
            : const Text(
          'Sign In',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: const [
        Expanded(
          child: Divider(
            thickness: 1,
            color: AppColors.divider,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            thickness: 1,
            color: AppColors.divider,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: GestureDetector(
        onTap: _navigateToRegister,
        child: RichText(
          text: const TextSpan(
            text: 'Don\'t have an account? ',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            children: [
              TextSpan(
                text: 'Sign Up',
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
    );
  }
}