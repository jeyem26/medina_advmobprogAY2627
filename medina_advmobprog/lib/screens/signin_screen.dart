import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _userService = UserService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // FIREBASE SIGN IN
  // ============================================================

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Firebase Authentication
      final credential = await _userService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception('Unable to retrieve user information.');
      }

      // Save login session.
      final preferences = await SharedPreferences.getInstance();

      await preferences.setBool(
        isLoggedInKey,
        true,
      );

      await preferences.setString(
        emailKey,
        firebaseUser.email ?? _emailController.text.trim(),
      );

      await preferences.setString(
        usernameKey,
        firebaseUser.displayName ?? '',
      );

      if (!mounted) return;

      // Go to Home.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error
            .toString()
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==================================================
                  // LOGO
                  // ==================================================

                  Icon(
                    Icons.storefront_rounded,
                    size: 64.sp,
                  ),

                  SizedBox(height: 12.h),

                  // ==================================================
                  // TITLE
                  // ==================================================

                  CustomText(
                    text: 'Bulldog Exchange',
                    fontSize: 25.sp,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 8.h),

                  const Text(
                    'Sign in to continue',
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 30.h),

                  // ==================================================
                  // EMAIL
                  // ==================================================

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Enter your email address';
                      }

                      final emailRegex = RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      );

                      if (!emailRegex.hasMatch(
                        value.trim(),
                      )) {
                        return 'Enter a valid email address';
                      }

                      return null;
                    },
                  ),

                  SizedBox(height: 14.h),

                  // ==================================================
                  // PASSWORD
                  // ==================================================

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                      ),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                                !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter your password';
                      }

                      return null;
                    },
                  ),

                  // ==================================================
                  // ERROR MESSAGE
                  // ==================================================

                  if (_errorMessage != null) ...[
                    SizedBox(height: 12.h),

                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .error,
                      ),
                    ),
                  ],

                  SizedBox(height: 22.h),

                  // ==================================================
                  // SIGN IN BUTTON
                  // ==================================================

                  SizedBox(
                    height: 50.h,
                    child: FilledButton(
                      onPressed:
                          _isLoading ? null : _signIn,
                      child: _isLoading
                          ? SizedBox(
                              height: 20.w,
                              width: 20.w,
                              child:
                                  const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Sign In'),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // ==================================================
                  // CREATE ACCOUNT
                  // ==================================================

                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pushNamed(
                              context,
                              '/signup',
                            );
                          },
                    child: const Text(
                      'Don\'t have an account? Create Account',
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