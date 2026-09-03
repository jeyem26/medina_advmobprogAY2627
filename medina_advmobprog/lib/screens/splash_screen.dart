import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../widgets/custom_text.dart';
import 'signin_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Enhancement 1: Persistent authentication using SharedPreferences.
    final preferences = await SharedPreferences.getInstance();
    final isLoggedIn = preferences.getBool(isLoggedInKey) ?? false;
    final userId = preferences.getInt(userIdKey);

    if (!mounted) return;
    final destination = isLoggedIn && userId != null
        ? const HomeScreen()
        : const SignInScreen();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_rounded, size: 72.sp),
            SizedBox(height: 18.h),
            CustomText(
              text: 'Bulldog Exchange',
              fontSize: 26.sp,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 8.h),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
