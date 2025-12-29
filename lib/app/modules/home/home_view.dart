import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:confetti/confetti.dart';
import 'package:lottie/lottie.dart';
import 'home_controller.dart';
import '../../services/ad_service.dart';
import '../../services/tutorial_service.dart';
import '../../services/storage_service.dart';
import '../../controllers/rewarded_controller.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/settings_drawer.dart';

class HomeView extends GetResponsiveView<HomeController> {
  HomeView({super.key});

  @override
  Widget? phone() => _HomeViewContent(isTablet: false);

  @override
  Widget? tablet() => _HomeViewContent(isTablet: true);
}

class _HomeViewContent extends GetView<HomeController> {
  final bool isTablet;
  // GlobalKeys for tutorial targets
  final GlobalKey micButtonKey = GlobalKey();
  final GlobalKey strongerButtonKey = GlobalKey();
  final GlobalKey crystalButtonKey = GlobalKey();
  final GlobalKey peaceModeButtonKey = GlobalKey();

  _HomeViewContent({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    // Trigger main tutorial after first frame if needed
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _showTutorialIfNeeded(context);
    });

    // Listen for bottom sheet appearing to show features tutorial
    ever(controller.showRewardButtons, (isShowing) {
      if (isShowing) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _showFeaturesTutorialIfNeeded(context);
        });
      }
    });

    return Obx(() {
      // Wait for services to be initialized
      if (!controller.servicesInitialized) {
        return const Scaffold(
          backgroundColor: Color(0xFF0a0520),
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xFF7B5EBF),
            ),
          ),
        );
      }

      final adService = controller.adService;
      final rewardedController = controller.rewardedController;

      if (adService == null || rewardedController == null) {
        return const Scaffold(
          backgroundColor: Color(0xFF0a0520),
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xFF7B5EBF),
            ),
          ),
        );
      }

      return _buildMainContent(context, adService, rewardedController);
    });
  }

  void _showTutorialIfNeeded(BuildContext context) {
    try {
      final tutorialService = Get.find<TutorialService>();
      final storageService = Get.find<StorageService>();

      // Only show main mic tutorial if user has seen onboarding but not the tutorial
      if (storageService.hasSeenOnboarding() && !tutorialService.hasSeenTutorial) {
        tutorialService.showTutorial(
          micButtonKey: micButtonKey,
          context: context,
        );
      }
    } catch (e) {
      // Tutorial service not available, skip
    }
  }

  void _showFeaturesTutorialIfNeeded(BuildContext context) {
    try {
      final tutorialService = Get.find<TutorialService>();

      // Show features tutorial after bottom sheet appears
      if (!tutorialService.hasSeenFeaturesTutorial) {
        tutorialService.showFeaturesTutorial(
          strongerButtonKey: strongerButtonKey,
          crystalButtonKey: crystalButtonKey,
          peaceModeButtonKey: peaceModeButtonKey,
          context: context,
        );
      }
    } catch (e) {
      // Tutorial service not available, skip
    }
  }

  Widget _buildMainContent(BuildContext context, AdService adService, RewardedController rewardedController) {
    final isTabletDevice = ResponsiveUtils.isTablet(context);

    // Load adaptive banner ad if not already loaded
    if (!adService.isBannerLoaded.value && adService.bannerAd == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        adService.loadAdaptiveBannerAd(context);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0a0520),
      endDrawer: const SettingsDrawer(),
      body: Stack(
        children: [
          // Premium Background Gradient (deep blue → purple → black)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0a0520), // Very dark blue-purple
                  Color(0xFF150a2e), // Deep purple
                  Color(0xFF0d0618), // Almost black
                ],
              ),
            ),
          ),

          // 2× STRONGER Electric Purple Flash Effect
          Obx(() => rewardedController.showStrongerFlash.value
              ? Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: const Color(0xFF9D7FFF).withOpacity(0.3), // Electric purple
                )
              : const SizedBox.shrink()),

          // Crystal Voice Sparkle Animation
          Obx(() => rewardedController.showCrystalSparkle.value
              ? Center(
                  child: SizedBox(
                    width: 200.w,
                    height: 200.w,
                    child: Lottie.asset(
                      'assets/animations/sparkle.json',
                      repeat: false,
                      animate: true,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to simple crystal glow
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFAB30FF).withOpacity(0.6),
                                blurRadius: 100,
                                spreadRadius: 50,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                )
              : const SizedBox.shrink()),

          // Main Content
          SafeArea(
            child: Stack(
              children: [
                // Center content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top Bar (minimal)
                    _buildMinimalTopBar(),

                    // Spacer - creates the 70-80% empty space
                    const Spacer(flex: 3),

                    // Instructional text above mic button
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTabletDevice ? 60 : 25.w,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'mic_instruction_line1'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTabletDevice ? 20 : 15.sp,
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: isTabletDevice ? 8 : 4.h),
                          Text(
                            'mic_instruction_line2'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTabletDevice ? 20 : 15.sp,
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isTabletDevice ? 40 : 50.h),

                    // Mic Button (center of screen)
                    _buildPremiumMicButton(),

                    // Spacer - equal flex to center the mic button
                    const Spacer(flex: 5),

                    // Banner Ad Space (only if loaded and not ad-free)
                    Obx(() => adService.isBannerLoaded.value
                        ? _buildBannerAd(adService)
                        : SizedBox(height: isTabletDevice ? 60 : 50.h)),
                  ],
                ),

                // Subtle active state indicators (non-intrusive)
                _buildActiveStateIndicators(),
              ],
            ),
          ),

          // Confetti (minimal, elegant)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: controller.confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30, // Reduced for elegance
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Color(0xFF6B4FBB), // Soft purple
                Color(0xFF9B7FDB), // Lavender
                Color(0xFF8B7FDB), // Light purple
              ],
            ),
          ),

          // Streak confetti
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: controller.streakController!.confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.03,
              numberOfParticles: 40,
              gravity: 0.15,
              shouldLoop: false,
              colors: const [
                Color(0xFFFFB74D), // Soft orange
                Color(0xFFFFA726), // Warm orange
                Color(0xFFFF9800), // Gentle amber
              ],
            ),
          ),

          // 2× STRONGER Power Overlay - REMOVED (only top snackbar is shown now)

          // Bottom Sheet for Superpower Buttons (appears after shift)
          Obx(() => controller.showRewardButtons.value
              ? _buildSuperpowerBottomSheet()
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  // Minimal top bar - clean and spacious
  Widget _buildMinimalTopBar() {
    final rewardedController = controller.rewardedController!;
    final adFreeController = controller.adFreeController!;

    return Builder(
      builder: (context) {
        final isTabletDevice = ResponsiveUtils.isTablet(context);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isTabletDevice ? 24 : 20.w),
          child: Column(
            children: [
              // Use Stack to center title absolutely, with Crystal timer and menu on sides
              SizedBox(
                height: isTabletDevice ? 44 : 40.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // App name - absolutely centered
                    Center(
                      child: Text(
                        'MoodShift AI',
                        style: TextStyle(
                          fontSize: isTabletDevice ? 20 : 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    // Crystal Voice Timer (left side) with stop button
                    Positioned(
                      left: 0,
                      child: Obx(() {
                        final timerText = rewardedController.getCrystalTimerDisplay();
                        if (timerText.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTabletDevice ? 14 : 10.w,
                            vertical: isTabletDevice ? 8 : 6.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE1BEE7), Color(0xFF7B1FA2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(isTabletDevice ? 24 : 20.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFAB30FF).withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.diamond,
                                color: Colors.white,
                                size: isTabletDevice ? 18 : 13.sp,
                              ),
                              SizedBox(width: isTabletDevice ? 6 : 4.w),
                              Text(
                                timerText,
                                style: TextStyle(
                                  fontSize: isTabletDevice ? 16 : 11.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              SizedBox(width: isTabletDevice ? 10 : 6.w),
                              // Stop button
                              GestureDetector(
                                onTap: () => rewardedController.stopCrystalVoice(),
                                child: Container(
                                  padding: EdgeInsets.all(isTabletDevice ? 4 : 2.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.stop_rounded,
                                    color: Colors.white,
                                    size: isTabletDevice ? 18 : 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    // Settings menu icon - opens drawer (right side)
                    Positioned(
                      right: 0,
                      child: Builder(
                        builder: (context) => IconButton(
                          onPressed: () => Scaffold.of(context).openEndDrawer(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.menu_rounded,
                            color: Colors.white.withOpacity(0.6),
                            size: isTabletDevice ? 26 : 24.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Peace Mode Timer (top center, below main bar)
              Obx(() {
                final peaceModeTimer = adFreeController.getPeaceModeTimerDisplay();
                if (peaceModeTimer.isEmpty) {
                  return SizedBox(height: isTabletDevice ? 40 : 35.h);
                }

                return Padding(
                  padding: EdgeInsets.only(top: isTabletDevice ? 12 : 10.h),
                  child: Center(
                    child: Container(
                      height: isTabletDevice ? 44 : 35.h,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTabletDevice ? 18 : 14.w,
                        vertical: isTabletDevice ? 10 : 8.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF81C784), Color(0xFF4CAF50)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(isTabletDevice ? 24 : 20.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.spa_rounded,
                            color: Colors.white,
                            size: isTabletDevice ? 20 : 14.sp,
                          ),
                          SizedBox(width: isTabletDevice ? 8 : 6.w),
                          Text(
                            'peace_mode'.tr,
                            style: TextStyle(
                              fontSize: isTabletDevice ? 16 : 11.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(width: isTabletDevice ? 8 : 6.w),
                          Text(
                            peaceModeTimer,
                            style: TextStyle(
                              fontSize: isTabletDevice ? 18 : 12.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // Active state indicators - removed as requested
  Widget _buildActiveStateIndicators() {
    return const SizedBox.shrink();
  }

  // Premium mic button - elegant, soft glow, breathing animation
  Widget _buildPremiumMicButton() {
    final rewardedController = controller.rewardedController!;

    return Obx(() {
      final isActive = controller.currentState.value != AppState.idle;
      final isListening = controller.currentState.value == AppState.listening;
      final isProcessing = controller.currentState.value == AppState.processing;
      final isSpeaking = controller.currentState.value == AppState.speaking;
      final isCrystal = rewardedController.hasCrystalVoice.value;

      return GestureDetector(
        key: micButtonKey,
        onTapDown: (_) => controller.onMicPressed(),
        onTapUp: (_) => controller.onMicReleased(),
        onTapCancel: () => controller.onMicReleased(),
        child: _BreathingMicButton(
          isListening: isListening,
          isSpeaking: isSpeaking,
          isProcessing: isProcessing,
          isActive: isActive,
          isCrystal: isCrystal,
        ),
      );
    });
  }

  // Superpower bottom sheet - elegant, slides up after shift
  Widget _buildSuperpowerBottomSheet() {
    final adFreeController = controller.adFreeController!;

    return Builder(
      builder: (context) {
        final isTabletDevice = ResponsiveUtils.isTablet(context);
        final isSmallPhone = ResponsiveUtils.isSmallPhone(context);
        final screenWidth = MediaQuery.of(context).size.width;

        // On tablet: constrain width and center the bottom sheet
        final sheetWidth = isTabletDevice ? 500.0 : screenWidth;
        final horizontalMargin = isTabletDevice ? (screenWidth - sheetWidth) / 2 : 0.0;

        // Use horizontal layout for small phones and tablets to save vertical space
        final useHorizontalLayout = isTabletDevice || isSmallPhone;

        return Positioned(
          bottom: 0,
          left: horizontalMargin,
          right: horizontalMargin,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, (1 - value) * 300),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF1a1030).withOpacity(0.95),
                          const Color(0xFF0d0618).withOpacity(0.98),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isTabletDevice ? 32 : 24.r),
                        topRight: Radius.circular(isTabletDevice ? 32 : 24.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isTabletDevice ? 32 : (isSmallPhone ? 16.w : 20.w),
                      vertical: isTabletDevice ? 20 : (isSmallPhone ? 16.h : 24.h),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle bar
                          Container(
                            width: isTabletDevice ? 50 : 40.w,
                            height: isTabletDevice ? 5 : 4.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(isTabletDevice ? 3 : 2.r),
                            ),
                          ),

                          SizedBox(height: isTabletDevice ? 16 : (isSmallPhone ? 12.h : 20.h)),

                          // Superpower cards - horizontal on tablet and small phones, vertical on regular phones
                          Obx(() {
                            final rewardedController = controller.rewardedController!;
                            final isCrystal = rewardedController.hasCrystalVoice.value;
                            final isPeaceMode = adFreeController.isPeaceModeActive.value;
                            final isBusy = controller.currentState.value == AppState.speaking ||
                                          controller.currentState.value == AppState.processing;

                            if (useHorizontalLayout) {
                              // Tablet and small phones: horizontal row layout to save vertical space
                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildSuperpowerCardCompact(
                                      'stronger_2x'.tr,
                                      Icons.bolt_outlined,
                                      isBusy ? null : controller.onMakeStronger,
                                      isActive: false,
                                      isSmallPhone: isSmallPhone,
                                      key: strongerButtonKey,
                                    ),
                                  ),
                                  SizedBox(width: isSmallPhone ? 8 : 12),
                                  Expanded(
                                    child: _buildSuperpowerCardCompact(
                                      isCrystal
                                          ? '${'crystal_active'.tr} • ${rewardedController.crystalTimeRemaining.value}'
                                          : 'crystal_voice'.tr,
                                      Icons.diamond_outlined,
                                      (isCrystal || isBusy) ? null : controller.onUnlockCrystal,
                                      isActive: isCrystal,
                                      isSmallPhone: isSmallPhone,
                                      key: crystalButtonKey,
                                    ),
                                  ),
                                  SizedBox(width: isSmallPhone ? 8 : 12),
                                  Expanded(
                                    child: _buildSuperpowerCardCompact(
                                      isPeaceMode
                                          ? '${'peace_active'.tr} • ${adFreeController.peaceModeTimeRemaining.value}'
                                          : 'peace_mode'.tr,
                                      Icons.spa_outlined,
                                      isPeaceMode ? null : controller.onActivatePeaceMode,
                                      isActive: isPeaceMode,
                                      isSmallPhone: isSmallPhone,
                                      key: peaceModeButtonKey,
                                    ),
                                  ),
                                ],
                              );
                            }

                            // Regular phone: vertical column layout
                            return Column(
                              children: [
                                _buildSuperpowerCard(
                                  'stronger_2x'.tr,
                                  Icons.bolt_outlined,
                                  isBusy ? null : controller.onMakeStronger,
                                  isActive: false,
                                  key: strongerButtonKey,
                                ),
                                SizedBox(height: 12.h),
                                _buildSuperpowerCard(
                                  isCrystal
                                      ? '${'crystal_active'.tr} • ${rewardedController.crystalTimeRemaining.value}'
                                      : 'crystal_voice'.tr,
                                  Icons.diamond_outlined,
                                  (isCrystal || isBusy) ? null : controller.onUnlockCrystal,
                                  isActive: isCrystal,
                                  key: crystalButtonKey,
                                ),
                                SizedBox(height: 12.h),
                                _buildSuperpowerCard(
                                  isPeaceMode
                                      ? '${'peace_mode'.tr} • ${adFreeController.peaceModeTimeRemaining.value}'
                                      : 'peace_mode'.tr,
                                  Icons.spa_outlined,
                                  isPeaceMode ? null : controller.onActivatePeaceMode,
                                  isActive: isPeaceMode,
                                  key: peaceModeButtonKey,
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Compact superpower card for tablet and small phone horizontal layout
  Widget _buildSuperpowerCardCompact(
    String title,
    IconData icon,
    VoidCallback? onTap, {
    bool isActive = false,
    bool isSmallPhone = false,
    GlobalKey? key,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallPhone ? 8 : 12,
          vertical: isSmallPhone ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.15)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(isSmallPhone ? 12 : 16),
          border: Border.all(
            color: isActive
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.8),
              size: isSmallPhone ? 22 : 28,
            ),
            SizedBox(height: isSmallPhone ? 4 : 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallPhone ? 11 : 13,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Individual superpower card - minimal, elegant
  Widget _buildSuperpowerCard(
    String text,
    IconData icon,
    VoidCallback? onTap, {
    bool isActive = false,
    GlobalKey? key,
  }) {
    return InkWell(
      key: key,
      onTap: isActive ? null : onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isActive
                ? const Color(0xFFA0A0FF).withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: isActive
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive
                  ? const Color(0xFFA0A0FF).withOpacity(0.6)
                  : Colors.white.withOpacity(0.8),
              size: 22.sp,
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: isActive
                      ? const Color(0xFFA0A0FF).withOpacity(0.7)
                      : Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (!isActive)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.3),
                size: 14.sp,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerAd(AdService adService) {
    // Use the adaptive banner size if available, otherwise fallback to standard height
    final adHeight = adService.bannerAdSize?.height.toDouble() ?? 50.0;

    return Container(
      width: double.infinity,
      height: adHeight,
      alignment: Alignment.center,
      color: Colors.transparent,
      child: adService.bannerAd != null
          ? AdWidget(ad: adService.bannerAd!)
          : const SizedBox.shrink(),
    );
  }

  // Habit stats widget - shows streak, today's shifts, total shifts, active days
  Widget _buildHabitStats() {
    final streakController = controller.streakController!;

    return Obx(() => Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Day X with fire icon (big)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Day ${streakController.currentStreak.value}',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              if (streakController.currentStreak.value >= 3) ...[
                SizedBox(width: 8.w),
                Text(
                  '🔥',
                  style: TextStyle(fontSize: 20.sp),
                ),
              ],
            ],
          ),

          // TODO: Uncomment to show day shifts and active days sections
          // SizedBox(height: 8.h),
          //
          // // Today's shifts
          // Text(
          //   'Today: ${HabitService.todayShifts} shift${HabitService.todayShifts == 1 ? '' : 's'}',
          //   style: TextStyle(
          //     fontSize: 13.sp,
          //     color: const Color(0xFF9B7FDB).withOpacity(0.8),
          //     fontWeight: FontWeight.w500,
          //     letterSpacing: 0.3,
          //   ),
          // ),
          //
          // SizedBox(height: 4.h),
          //
          // // Total shifts and active days
          // Text(
          //   'Total: ${streakController.totalShifts.value} shifts • ${HabitService.activeDays} active day${HabitService.activeDays == 1 ? '' : 's'}',
          //   style: TextStyle(
          //     fontSize: 11.sp,
          //     color: Colors.white.withOpacity(0.5),
          //     fontWeight: FontWeight.w400,
          //     letterSpacing: 0.3,
          //   ),
          // ),
        ],
      ),
    ));
  }
}

// Premium press-and-hold mic button with beautiful animations
class _BreathingMicButton extends StatefulWidget {
  final bool isListening;
  final bool isSpeaking;
  final bool isProcessing;
  final bool isActive;
  final bool isCrystal;

  const _BreathingMicButton({
    required this.isListening,
    required this.isSpeaking,
    required this.isProcessing,
    required this.isActive,
    required this.isCrystal,
  });

  @override
  State<_BreathingMicButton> createState() => _BreathingMicButtonState();
}

class _BreathingMicButtonState extends State<_BreathingMicButton>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _pulseController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Subtle breathing animation when idle
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );

    // Pulsing glow ring animation when recording
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didUpdateWidget(_BreathingMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start/stop pulse animation based on listening, processing, or speaking state
    final isActiveNow = widget.isListening || widget.isSpeaking || widget.isProcessing;
    final wasActive = oldWidget.isListening || oldWidget.isSpeaking || oldWidget.isProcessing;

    if (isActiveNow && !wasActive) {
      _pulseController.repeat(reverse: true);
    } else if (!isActiveNow && wasActive) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main button with animations
        AnimatedBuilder(
          animation: Listenable.merge([_breathingAnimation, _pulseAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: (widget.isListening || widget.isSpeaking) ? 1.0 : _breathingAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing glow rings (when recording)
                  if (widget.isListening) ...[
                    // Outer glow ring
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        final size = ResponsiveUtils.micButtonSize(context) * 1.3;
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF6D5FFD).withOpacity(0.0),
                                  const Color(0xFF6D5FFD).withOpacity(0.3),
                                  const Color(0xFF1E1E3F).withOpacity(0.5),
                                ],
                                stops: const [0.0, 0.7, 1.0],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Middle glow ring
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        final size = ResponsiveUtils.micButtonSize(context) * 1.2;
                        return Transform.scale(
                          scale: 1.0 + (_pulseAnimation.value - 1.0) * 0.6,
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF6D5FFD).withOpacity(0.0),
                                  const Color(0xFF6D5FFD).withOpacity(0.4),
                                  const Color(0xFF1E1E3F).withOpacity(0.6),
                                ],
                                stops: const [0.0, 0.6, 1.0],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  // Wavy rings (when Polly is speaking)
                  if (widget.isSpeaking) ...[
                    _WaveRing(size: ResponsiveUtils.micButtonSize(context) * 1.4, delay: 0),
                    _WaveRing(size: ResponsiveUtils.micButtonSize(context) * 1.2, delay: 300),
                    _WaveRing(size: ResponsiveUtils.micButtonSize(context), delay: 600),
                  ],

                  // Main button with size animation
                  Builder(builder: (context) {
                    final baseSize = ResponsiveUtils.micButtonSize(context);
                    final activeSize = baseSize * 1.1;
                    final inactiveSize = baseSize * 0.86;
                    return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: (widget.isListening || widget.isSpeaking) ? activeSize : inactiveSize,
                    height: (widget.isListening || widget.isSpeaking) ? activeSize : inactiveSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: widget.isCrystal
                          ? const LinearGradient(
                              colors: [Color(0xFFE1BEE7), Color(0xFF7B1FA2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: widget.isCrystal ? null : Colors.white,
                      boxShadow: [
                        // Soft shadow
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                        // Glow effect when listening
                        if (widget.isListening)
                          BoxShadow(
                            color: const Color(0xFF6D5FFD).withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        // Glow effect when speaking
                        if (widget.isSpeaking)
                          BoxShadow(
                            color: const Color(0xFF6D5FFD).withOpacity(0.3),
                            blurRadius: 25,
                            spreadRadius: 3,
                          ),
                        if (widget.isCrystal)
                          BoxShadow(
                            color: const Color(0xFFAB30FF).withOpacity(0.7),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                      ],
                    ),
                    child: Center(
                      child: _buildMicIcon(),
                    ),
                  );
                  }),

                  // Crystal Voice sparkle overlay
                  if (widget.isCrystal)
                    Builder(builder: (context) {
                      final baseSize = ResponsiveUtils.micButtonSize(context);
                      final activeSize = baseSize * 1.3;
                      final inactiveSize = baseSize * 1.06;
                      return SizedBox(
                        width: (widget.isListening || widget.isSpeaking) ? activeSize : inactiveSize,
                        height: (widget.isListening || widget.isSpeaking) ? activeSize : inactiveSize,
                        child: Lottie.asset(
                          'assets/animations/sparkle.json',
                          repeat: true,
                          animate: true,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox.shrink();
                          },
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),

        // "Recording...", "Thinking...", or "Speaking..." text
        AnimatedOpacity(
          opacity: (widget.isListening || widget.isSpeaking || widget.isProcessing) ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: (widget.isListening || widget.isSpeaking || widget.isProcessing) ? 30.h : 0,
            child: (widget.isListening || widget.isSpeaking || widget.isProcessing)
                ? Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          child: Text(
                            widget.isListening ? 'recording'.tr : (widget.isProcessing ? 'thinking'.tr : 'speaking_state'.tr),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFFA0A0FF),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        _buildPulsingDots(),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  // Mic icon with sound wave animation when recording or volume icon when speaking
  Widget _buildMicIcon() {
    final iconSize = ResponsiveUtils.scaledIconSize(40, context);
    final idleIconSize = ResponsiveUtils.scaledIconSize(36, context);

    if (widget.isListening) {
      // Show mic icon when recording
      return Icon(
        Icons.mic_none_rounded,
        size: iconSize,
        color: widget.isCrystal
            ? Colors.white
            : const Color(0xFF1E1E3F),
      );
    } else if (widget.isSpeaking) {
      // Show volume icon when speaking
      return Icon(
        Icons.volume_up_rounded,
        size: iconSize,
        color: widget.isCrystal
            ? Colors.white
            : const Color(0xFF1E1E3F),
      );
    } else {
      // Idle state - simple mic icon
      return Icon(
        Icons.mic_none_rounded,
        size: idleIconSize,
        color: widget.isCrystal
            ? Colors.white
            : const Color(0xFF1E1E3F),
      );
    }
  }

  // Pulsing dots animation for "Recording..."
  Widget _buildPulsingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PulsingDot(delay: 0),
        SizedBox(width: 2.w),
        _PulsingDot(delay: 150),
        SizedBox(width: 2.w),
        _PulsingDot(delay: 300),
      ],
    );
  }
}

// Sound wave bar animation
class _SoundWaveBar extends StatefulWidget {
  final int delay;

  const _SoundWaveBar({required this.delay});

  @override
  State<_SoundWaveBar> createState() => _SoundWaveBarState();
}

class _SoundWaveBarState extends State<_SoundWaveBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Delay start based on position
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 3.w,
          height: 12.h * _animation.value,
          decoration: BoxDecoration(
            color: (widget.delay == 0 ? const Color(0xFF6D5FFD) : const Color(0xFF1E1E3F))
                .withOpacity(0.6),
            borderRadius: BorderRadius.circular(2.r),
          ),
        );
      },
    );
  }
}

// Pulsing dot for "Recording..." text
class _PulsingDot extends StatefulWidget {
  final int delay;

  const _PulsingDot({required this.delay});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Delay start based on position
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 4.w,
          height: 4.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFA0A0FF).withOpacity(_animation.value),
          ),
        );
      },
    );
  }
}

// Wave ring animation for speaking state
class _WaveRing extends StatefulWidget {
  final double size;
  final int delay;

  const _WaveRing({
    required this.size,
    required this.delay,
  });

  @override
  State<_WaveRing> createState() => _WaveRingState();
}

class _WaveRingState extends State<_WaveRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Start animation after delay
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF6D5FFD)
                      .withOpacity(_opacityAnimation.value.clamp(0.0, 1.0)),
                  width: 2.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Speaking wave bar animation (for volume icon)
class _SpeakingWaveBar extends StatefulWidget {
  final int index;

  const _SpeakingWaveBar({required this.index});

  @override
  State<_SpeakingWaveBar> createState() => _SpeakingWaveBarState();
}

class _SpeakingWaveBarState extends State<_SpeakingWaveBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600 + (widget.index * 100)),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Delay start based on index for wave effect
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Different heights for each bar to create wave effect
        final baseHeight = [8.h, 14.h, 10.h, 12.h][widget.index];

        return Container(
          width: 2.5.w,
          height: baseHeight * _animation.value,
          decoration: BoxDecoration(
            color: const Color(0xFF6D5FFD).withOpacity(0.7),
            borderRadius: BorderRadius.circular(2.r),
          ),
        );
      },
    );
  }
}

