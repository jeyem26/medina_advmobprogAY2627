import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../services/user_service.dart';
import 'auth_selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  late Future<firebase_auth.User?> _userFuture;
  String? _updatedUsername;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }

  // ============================================================
  // LOAD FIREBASE USER
  // ============================================================

  Future<firebase_auth.User?> _loadUser() async {
    return await _userService.getUserData();
  }

  // ============================================================
  // UPDATE USERNAME
  // ============================================================

  Future<void> _showUpdateUsernameDialog(firebase_auth.User user) async {
    final newUsername = await showDialog<String>(
      context: context,
      builder: (_) => _UpdateUsernameDialog(
        initialUsername: user.displayName ?? '',
        onUpdate: _userService.updateUsername,
      ),
    );

    if (newUsername == null || newUsername.isEmpty) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _updatedUsername = newUsername;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Username updated successfully.')),
    );
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<void> _showChangePasswordDialog(firebase_auth.User user) async {
    final currentPasswordController = TextEditingController();

    final newPasswordController = TextEditingController();

    final confirmPasswordController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    final passwords = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter your current password';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter a new password';
                      }

                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirm your new password';
                      }

                      if (value != newPasswordController.text) {
                        return 'Passwords do not match';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, [
                    currentPasswordController.text,
                    newPasswordController.text,
                  ]);
                }
              },
              child: const Text('Change Password'),
            ),
          ],
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (passwords == null) {
      return;
    }

    try {
      await _userService.resetPasswordFromCurrentPassword(
        currentPassword: passwords[0],
        newPassword: passwords[1],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  // ============================================================
  // DELETE ACCOUNT
  // ============================================================

  Future<void> _deleteAccount(firebase_auth.User user) async {
    final passwordController = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This action cannot be undone. '
                'Enter your current password to confirm '
                'account deletion.',
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (passwordController.text.isNotEmpty) {
                  Navigator.pop(dialogContext, passwordController.text);
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    passwordController.dispose();

    if (password == null || password.isEmpty) {
      return;
    }

    try {
      await _userService.deleteAccount(password: password);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthSelectionScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    try {
      await _userService.signOut();
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(isLoggedInKey);
      await preferences.remove(authMethodKey);
      await preferences.remove(userIdKey);
      await preferences.remove(accessTokenKey);
      await preferences.remove(emailKey);
      await preferences.remove(usernameKey);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthSelectionScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  // ============================================================
  // PROFILE UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<firebase_auth.User?>(
      future: _userFuture,
      builder: (context, snapshot) {
        // --------------------------------------------------------
        // LOADING
        // --------------------------------------------------------

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // --------------------------------------------------------
        // ERROR
        // --------------------------------------------------------

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Text(
                'Unable to load profile:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // --------------------------------------------------------
        // NO USER
        // --------------------------------------------------------

        final user = snapshot.data;

        if (user == null) {
          return _buildDummyJsonProfile();
        }

        // --------------------------------------------------------
        // USER INFORMATION
        // --------------------------------------------------------

        final username =
            _updatedUsername ??
            (user.displayName?.trim().isNotEmpty == true
                ? user.displayName!
                : 'No username set');

        final email = user.email ?? 'No email available';

        // --------------------------------------------------------
        // PROFILE CONTENT
        // --------------------------------------------------------

        return SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================================================
              // PROFILE IMAGE
              // ==================================================
              Center(
                child: CircleAvatar(
                  radius: 52.r,
                  child: Icon(Icons.person, size: 48.sp),
                ),
              ),

              SizedBox(height: 14.h),

              // ==================================================
              // USERNAME
              // ==================================================
              Text(
                username,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 6.h),

              // ==================================================
              // EMAIL
              // ==================================================
              Text(
                email,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp),
              ),

              SizedBox(height: 24.h),

              // ==================================================
              // ACCOUNT INFORMATION
              // ==================================================
              Card(
                child: Column(
                  children: [
                    _ProfileRow(
                      label: 'Username',
                      value: username,
                      icon: Icons.person_outline,
                    ),

                    _ProfileRow(
                      label: 'Email',
                      value: email,
                      icon: Icons.email_outlined,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showUpdateUsernameDialog(user);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Update Username'),
                ),
              ),

              SizedBox(height: 12.h),

              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showChangePasswordDialog(user);
                  },
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Change Password'),
                ),
              ),

              SizedBox(height: 12.h),

              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _deleteAccount(user);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Account'),
                ),
              ),

              SizedBox(height: 12.h),

              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: FilledButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                ),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDummyJsonProfile() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final preferences = snapshot.data;
        final isDummyJsonSession =
            preferences?.getString(authMethodKey) == dummyJsonAuthMethod &&
            preferences?.getInt(userIdKey) != null &&
            (preferences?.getString(accessTokenKey)?.isNotEmpty ?? false);

        if (!isDummyJsonSession) {
          return const Center(child: Text('No signed-in user was found.'));
        }

        final username = preferences!.getString(usernameKey) ?? 'User';
        final email = preferences.getString(emailKey) ?? 'No email available';

        return SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 52.r,
                  child: Icon(Icons.person, size: 48.sp),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                username,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6.h),
              Text(email, textAlign: TextAlign.center),
              SizedBox(height: 24.h),
              Card(
                child: Column(
                  children: [
                    _ProfileRow(
                      label: 'Username',
                      value: username,
                      icon: Icons.person_outline,
                    ),
                    _ProfileRow(
                      label: 'Email',
                      value: email,
                      icon: Icons.email_outlined,
                    ),
                    const _ProfileRow(
                      label: 'Sign-in method',
                      value: 'DummyJSON',
                      icon: Icons.login,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: FilledButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UpdateUsernameDialog extends StatefulWidget {
  const _UpdateUsernameDialog({
    required this.initialUsername,
    required this.onUpdate,
  });

  final String initialUsername;
  final Future<void> Function({required String username}) onUpdate;

  @override
  State<_UpdateUsernameDialog> createState() => _UpdateUsernameDialogState();
}

class _UpdateUsernameDialogState extends State<_UpdateUsernameDialog> {
  late final TextEditingController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isUpdating = false;
  String? _updateError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _controller.text.trim();
    setState(() {
      _isUpdating = true;
      _updateError = null;
    });

    try {
      await widget.onUpdate(username: username);
      if (mounted) Navigator.pop(context, username);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isUpdating = false;
        _updateError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Username'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _controller,
              enabled: !_isUpdating,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username is required';
                }
                if (value.trim().length < 3) {
                  return 'Username must be at least 3 characters';
                }
                return null;
              },
            ),
            if (_updateError != null) ...[
              const SizedBox(height: 8),
              Text(
                _updateError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isUpdating ? null : _update,
          child: _isUpdating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value.isEmpty ? 'Not provided' : value),
    );
  }
}
