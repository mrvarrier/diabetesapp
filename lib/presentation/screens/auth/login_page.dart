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

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Sign in with email and password
      await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Log analytics event
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      analyticsService.logSessionStart();

      // Navigate to home
      AppRouter.navigateToAndRemoveUntil('/home');
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email address.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        default:
          message = 'An error occurred. Please try again later.';
      }

      setState(() {
        _errorMessage = message;
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Hero(
                    tag: 'app_logo',
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    StringConstants.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Your diabetes education companion',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

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
                    textInputAction: TextInputAction.done,
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
                    onFieldSubmitted: (_) => _signIn(),
                  ),
                  const SizedBox(height: 16),

                  // Error message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Forgot password button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        AppRouter.navigateTo('/forgot-password');
                      },
                      child: Text(StringConstants.forgotPassword),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  CustomButton(
                    text: StringConstants.signIn,
                    isLoading: _isLoading,
                    onPressed: _signIn,
                  ),
                  const SizedBox(height: 24),

                  // Register link
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: StringConstants.dontHaveAccount,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      children: [
                        TextSpan(
                          text: StringConstants.signUp,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              AppRouter.navigateTo('/register');
                            },
                        ),
                      ],
                    ),
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