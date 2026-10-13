import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/custom_text.dart';

class AuthSelectionScreen extends StatelessWidget {
  const AuthSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.storefront_rounded, size: 64.sp),
                SizedBox(height: 12.h),
                CustomText(
                  text: 'Bulldog Exchange',
                  fontSize: 25.sp,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 28.h),
                SizedBox(
                  height: 50.h,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/dummy-login'),
                    child: const Text('DummyJSON Login'),
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  height: 50.h,
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/firebase-login'),
                    child: const Text('Firebase Login'),
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
