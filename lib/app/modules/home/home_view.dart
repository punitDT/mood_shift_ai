import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:confetti/confetti.dart';
import 'home_controller.dart';
import '../../services/ad_service.dart';
import '../../controllers/ad_free_controller.dart';
import '../../controllers/streak_controller.dart';

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

                // Golden Voice Timer (at top)
                SizedBox(height: 16.h),
                _buildGoldenTimer(),

                // Ad-Free Timer
                SizedBox(height: 8.h),
                _buildAdFreeTimer(),

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

          // Confetti (Main shift completion)
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

          // Confetti (Streak celebration)
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: Get.find<StreakController>().confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.03,
              numberOfParticles: 70,
              gravity: 0.15,
              shouldLoop: false,
              colors: const [
                Colors.orange,
                Colors.deepOrange,
                Colors.amber,
                Colors.yellow,
                Colors.red,
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
    final streakController = Get.find<StreakController>();

    return Obx(() {
      final current = streakController.currentStreak.value;
      final total = streakController.totalShifts.value;
      final showFire = streakController.shouldShowFire();

      // Different UI for different states
      if (current == 0) {
        // First time user
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(0.3),
                Colors.blue.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.rocket_launch_rounded,
                color: Colors.white,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Start your journey! 🌟',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      } else if (current == 1) {
        // Day 1 - Special welcome message
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.pink.withOpacity(0.3),
                Colors.purple.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Colors.pink.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_rounded,
                color: Colors.pink.shade200,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Day 1 – Welcome! Keep coming back ❤️',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      } else {
        // Day 2+ - Show streak with fire emoji if >= 3
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: showFire
                  ? [
                      Colors.orange.withOpacity(0.3),
                      Colors.deepOrange.withOpacity(0.3),
                    ]
                  : [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: showFire
                  ? Colors.orange.withOpacity(0.5)
                  : Colors.white.withOpacity(0.2),
              width: showFire ? 1.5 : 1,
            ),
            boxShadow: showFire
                ? [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showFire)
                Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.orange,
                  size: 24.sp,
                )
              else
                Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white70,
                  size: 20.sp,
                ),
              SizedBox(width: 8.w),
              Text(
                showFire
                    ? 'Day $current 🔥 • $total shifts saved'
                    : 'Day $current • $total shifts saved',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  Widget _buildGoldenTimer() {
    return Obx(() {
      final isGolden = controller.hasGoldenVoice.value;
      final timeRemaining = controller.goldenTimeRemaining.value;

      if (!isGolden || timeRemaining.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          borderRadius: BorderRadius.circular(25.r),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.white, size: 20),
            SizedBox(width: 8.w),
            Text(
              'Golden Voice: $timeRemaining',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAdFreeTimer() {
    final adFreeController = Get.find<AdFreeController>();

    return Obx(() {
      if (!adFreeController.isAdFree.value) {
        return const SizedBox.shrink();
      }

      final timeRemaining = adFreeController.adFreeTimeRemaining.value;

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.withOpacity(0.3),
              Colors.teal.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: Colors.green.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.spa_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8.w),
            Text(
              'Ad-free: $timeRemaining',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMicButton() {
    return Obx(() {
      final isActive = controller.currentState.value != AppState.idle;
      final isListening = controller.currentState.value == AppState.listening;
      final isGolden = controller.hasGoldenVoice.value;

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
              colors: isGolden
                  ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                  : isListening
                      ? [Colors.red, Colors.pink]
                      : [Colors.purple, Colors.deepPurple],
            ),
            boxShadow: [
              BoxShadow(
                color: isGolden
                    ? Colors.amber.withOpacity(0.3)
                    : isListening
                        ? Colors.red.withOpacity(0.25)
                        : Colors.purple.withOpacity(0.25),
                blurRadius: isGolden ? 30 : (isListening ? 25 : 15),
                spreadRadius: isGolden ? 8 : (isListening ? 5 : 3),
              ),
              // Extra sparkle for golden
              if (isGolden)
                BoxShadow(
                  color: Colors.yellow.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 10,
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
    final adFreeController = Get.find<AdFreeController>();

    return Obx(() {
      final isGolden = controller.hasGoldenVoice.value;
      final goldenText = isGolden
          ? 'Golden Active – ${controller.goldenTimeRemaining.value}'
          : 'unlock_golden'.tr;

      final isAdFree = adFreeController.isAdFree.value;
      final adFreeText = isAdFree
          ? '${'ad_free_active'.tr}${adFreeController.adFreeTimeRemaining.value}'
          : 'remove_ads'.tr;

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
              goldenText,
              Icons.star_rounded,
              isGolden ? Colors.amber.shade700 : Colors.amber,
              isGolden ? null : controller.onUnlockGolden,
              isDisabled: isGolden,
            ),
            SizedBox(height: 12.h),
            _buildRewardButton(
              adFreeText,
              isAdFree ? Icons.spa_rounded : Icons.block_rounded,
              isAdFree ? Colors.green.shade700 : Colors.green,
              isAdFree ? null : controller.onRemoveAds,
              isDisabled: isAdFree,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRewardButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback? onTap, {
    bool isDisabled = false,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.6 : 1.0,
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

