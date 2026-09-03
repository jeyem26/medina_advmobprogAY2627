import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import 'signin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<User> _userFuture;
  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }

  Future<User> _loadUser() async {
    final preferences = await SharedPreferences.getInstance();
    final userId = preferences.getInt(userIdKey);
    if (userId == null) throw Exception('No signed-in user was found');
    return _userService.getUserById(userId);
  }

  Future<void> _logout() async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.remove(isLoggedInKey),
      preferences.remove(userIdKey),
      preferences.remove(accessTokenKey),
      preferences.remove(usernameKey),
      preferences.remove(emailKey),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Enhancement 3: Profile screen renders saved user's API data using User model.
    return FutureBuilder<User>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text('Unable to load profile: ${snapshot.error}'),
          );
        }

        final user = snapshot.data!;
        return SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              CircleAvatar(
                radius: 52.r,
                backgroundImage: user.image.isEmpty
                    ? null
                    : NetworkImage(user.image),
                child: user.image.isEmpty
                    ? Icon(Icons.person, size: 48.sp)
                    : null,
              ),
              SizedBox(height: 14.h),
              Text(
                '${user.firstName} ${user.lastName}'.trim(),
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.h),
              _ProfileRow(label: 'User ID', value: '${user.id}'),
              _ProfileRow(label: 'Username', value: user.username),
              _ProfileRow(label: 'Email', value: user.email),
              _ProfileRow(label: 'Gender', value: user.gender),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: OutlinedButton.icon(
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

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value.isEmpty ? 'Not provided' : value),
    );
  }
}
