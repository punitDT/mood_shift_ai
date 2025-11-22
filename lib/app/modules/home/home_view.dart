import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:confetti/confetti.dart';
import 'home_controller.dart';
import '../../services/ad_service.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final adService = Get.find<AdService>();

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
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
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(),

                // Streak Info
                SizedBox(height: 20.h),
                _buildStreakInfo(),

                // Spacer
                const Spacer(),

                // Status Text
                Obx(() => Text(
                      controller.statusText.value.tr,
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    )),

                SizedBox(height: 30.h),

                // Mic Button
                _buildMicButton(),

                SizedBox(height: 40.h),

                // Rewarded Ad Buttons
                Obx(() => controller.showRewardButtons.value
                    ? _buildRewardButtons()
                    : const SizedBox.shrink()),

                const Spacer(),

                // Banner Ad Space
                Obx(() => adService.isBannerLoaded.value
                    ? _buildBannerAd(adService)
                    : SizedBox(height: 50.h)),
              ],
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: controller.confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.purple,
                Colors.pink,
                Colors.blue,
                Colors.amber,
                Colors.green,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'app_name'.tr,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: controller.goToSettings,
            icon: Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 28.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakInfo() {
    return Obx(() => Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: Colors.orange,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                '${'day'.tr} ${controller.streakDay.value} • ${controller.todayShifts.value} ${controller.todayShifts.value == 1 ? 'shift'.tr : 'shifts'.tr}',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildMicButton() {
    return Obx(() {
      final isActive = controller.currentState.value != AppState.idle;
      final isListening = controller.currentState.value == AppState.listening;

      return GestureDetector(
        onTapDown: (_) => controller.onMicPressed(),
        onTapUp: (_) => controller.onMicReleased(),
        onTapCancel: () => controller.onMicReleased(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isListening ? 140.w : 120.w,
          height: isListening ? 140.w : 120.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isListening
                  ? [Colors.red, Colors.pink]
                  : [Colors.purple, Colors.deepPurple],
            ),
            boxShadow: [
              BoxShadow(
                color: isListening
                    ? Colors.red.withOpacity(0.5)
                    : Colors.purple.withOpacity(0.5),
                blurRadius: isListening ? 30 : 20,
                spreadRadius: isListening ? 10 : 5,
              ),
            ],
          ),
          child: Icon(
            isActive ? Icons.mic : Icons.mic_none_rounded,
            size: 50.sp,
            color: Colors.white,
          ),
        ),
      );
    });
  }

  Widget _buildRewardButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          _buildRewardButton(
            'make_stronger'.tr,
            Icons.bolt_rounded,
            Colors.orange,
            controller.onMakeStronger,
          ),
          SizedBox(height: 12.h),
          _buildRewardButton(
            'unlock_golden'.tr,
            Icons.star_rounded,
            Colors.amber,
            controller.onUnlockGolden,
          ),
          SizedBox(height: 12.h),
          _buildRewardButton(
            'remove_ads'.tr,
            Icons.block_rounded,
            Colors.green,
            controller.onRemoveAds,
          ),
        ],
      ),
    );
  }

  Widget _buildRewardButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
          ),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerAd(AdService adService) {
    return Container(
      width: double.infinity,
      height: 50.h,
      color: Colors.transparent,
      child: adService.bannerAd != null
          ? AdWidget(ad: adService.bannerAd!)
          : const SizedBox.shrink(),
    );
  }
}

