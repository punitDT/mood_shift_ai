import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    print('SplashView build called');
    // Trigger controller initialization
    try {
      final ctrl = controller;
      print('SplashView controller accessed: $ctrl');
    } catch (e) {
      print('SplashView ERROR accessing controller: $e');
    }
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a0f2e),
              const Color(0xFF2d1b4e),
              const Color(0xFF4a2c6f),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon/Logo
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.mic_rounded,
                size: 60.sp,
                color: Colors.white,
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // App Name
            Text(
              'app_name'.tr,
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            
            SizedBox(height: 8.h),
            
            // Tagline
            Text(
              '🧠 Your ADHD Companion ✨',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: 60.h),
            
            // Loading indicator
            SizedBox(
              width: 40.w,
              height: 40.w,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.8),
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            Text(
              'loading'.tr,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

