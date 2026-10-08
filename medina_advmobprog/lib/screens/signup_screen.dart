import 'package:flutter/material.dart';

import '../services/user_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // ============================================================
  // TEXT CONTROLLERS
  // ============================================================

  final TextEditingController _firstNameController =
      TextEditingController();

  final TextEditingController _lastNameController =
      TextEditingController();

  final TextEditingController _ageController =
      TextEditingController();

  final TextEditingController _contactNoController =
      TextEditingController();

  final TextEditingController _usernameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final UserService _userService = UserService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _contactNoController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // CREATE ACCOUNT
  // ============================================================

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create Firebase account using email and password.
      await _userService.createAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Save the username as the Firebase display name.
      await _userService.updateUsername(
        username: _usernameController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
        ),
      );

      // Go to home after successful registration.
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
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

  // ============================================================
  // VALIDATORS
  // ============================================================

  String? _requiredValidator(
    String? value,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  String? _ageValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }

    final age = int.tryParse(value.trim());

    if (age == null) {
      return 'Enter a valid age';
    }

    if (age < 1 || age > 120) {
      return 'Enter an age between 1 and 120';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),

                const Text(
                  'Create your account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                const Text(
                  'Enter your information to get started.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                // ==================================================
                // FIRST NAME
                // ==================================================

                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    label: 'First Name',
                    icon: Icons.person_outline,
                  ),
                  validator: (value) {
                    return _requiredValidator(
                      value,
                      'First name',
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ==================================================
                // LAST NAME
                // ==================================================

                TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    label: 'Last Name',
                    icon: Icons.person_outline,
                  ),
                  validator: (value) {
                    return _requiredValidator(
                      value,
                      'Last name',
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ==================================================
                // AGE
                // ==================================================

                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    label: 'Age',
                    icon: Icons.cake_outlined,
                  ),
                  validator: _ageValidator,
                ),

                const SizedBox(height: 16),

                // ==================================================
                // CONTACT NUMBER
                // ==================================================

                TextFormField(
                  controller: _contactNoController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(
                    label: 'Contact Number',
                    icon: Icons.phone_outlined,
                  ),
                  validator: (value) {
                    return _requiredValidator(
                      value,
                      'Contact number',
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ==================================================
                // USERNAME
                // ==================================================

                TextFormField(
                  controller: _usernameController,
                  decoration: _inputDecoration(
                    label: 'Username',
                    icon: Icons.account_circle_outlined,
                  ),
                  validator: (value) {
                    return _requiredValidator(
                      value,
                      'Username',
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ==================================================
                // EMAIL
                // ==================================================

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                  ),
                  validator: _emailValidator,
                ),

                const SizedBox(height: 16),

                // ==================================================
                // PASSWORD
                // ==================================================

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration(
                    label: 'Password',
                    icon: Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: _passwordValidator,
                ),

                const SizedBox(height: 24),

                // ==================================================
                // CREATE ACCOUNT BUTTON
                // ==================================================

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading ? null : _createAccount,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // BACK TO LOGIN
                // ==================================================

                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text(
                    'Already have an account? Login',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}