import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:confetti/confetti.dart';
import 'package:lottie/lottie.dart';
import 'home_controller.dart';
import '../../services/ad_service.dart';
import '../../services/habit_service.dart';
import '../../controllers/ad_free_controller.dart';
import '../../controllers/streak_controller.dart';
import '../../controllers/rewarded_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final adService = Get.find<AdService>();
    final rewardedController = Get.find<RewardedController>();

    return Scaffold(
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

          // 2× STRONGER Electric Blue Flash Effect
          Obx(() => rewardedController.showStrongerFlash.value
              ? Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: const Color(0xFF00D4FF).withOpacity(0.3), // Electric cyan
                )
              : const SizedBox.shrink()),

          // Golden Voice Sparkle Animation
          Obx(() => rewardedController.showGoldenSparkle.value
              ? Center(
                  child: SizedBox(
                    width: 200.w,
                    height: 200.w,
                    child: Lottie.asset(
                      'assets/animations/sparkle.json',
                      repeat: false,
                      animate: true,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to simple golden glow
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withOpacity(0.5),
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
                  children: [
                    // Top Bar (minimal)
                    _buildMinimalTopBar(),

                    // Spacer - creates the 70-80% empty space
                    const Spacer(flex: 1),

                    // Instructional text above mic button
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.w),
                      child: Text(
                        'mic_instruction'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const Spacer(flex: 1),

                    // Mic Button (center of screen)
                    _buildPremiumMicButton(),

                    // Spacer
                    const Spacer(flex: 5),

                    SizedBox(height: 20.h),

                    // Banner Ad Space (only if loaded and not ad-free)
                    Obx(() => adService.isBannerLoaded.value
                        ? _buildBannerAd(adService)
                        : SizedBox(height: 50.h)),
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
                Color(0xFF4A90E2), // Soft blue
              ],
            ),
          ),

          // Streak confetti
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: Get.find<StreakController>().confettiController,
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

          // 2× STRONGER Power Overlay
          Obx(() => rewardedController.showStrongerOverlay.value
              ? Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0099FF).withOpacity(0.95), // Electric blue
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D4FF).withOpacity(0.6), // Electric cyan glow
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt,
                          color: Colors.white,
                          size: 60.sp,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          '⚡ 2× POWER ACTIVATED! ⚡',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink()),

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
    final rewardedController = Get.find<RewardedController>();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
          Row(
            children: [
              // Golden Voice Timer (left side) - flexible to prevent overflow
              Obx(() {
                final timerText = rewardedController.getGoldenTimerDisplay();
                if (timerText.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: const Color(0xFFD4AF37),
                        size: 13.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        timerText,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFFD4AF37),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                );
              }),

              // App name - centered, flexible
              Expanded(
                child: Center(
                  child: Text(
                    'MoodShift AI',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),

              // Settings icon - stays on the right
              IconButton(
                onPressed: controller.goToSettings,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.settings_outlined,
                  color: Colors.white.withOpacity(0.6),
                  size: 22.sp,
                ),
              ),
            ],
          ),

          // Habit stats - clean and informative
          SizedBox(height: 12.h),
          _buildHabitStats(),
        ],
      ),
    );
  }

  // Active state indicators - removed as requested
  Widget _buildActiveStateIndicators() {
    return const SizedBox.shrink();
  }

  // Premium mic button - elegant, soft glow, breathing animation with Lottie and circular progress
  Widget _buildPremiumMicButton() {
    final rewardedController = Get.find<RewardedController>();

    return Obx(() {
      final isActive = controller.currentState.value != AppState.idle;
      final isListening = controller.currentState.value == AppState.listening;
      final isSpeaking = controller.currentState.value == AppState.speaking;
      final isGolden = rewardedController.hasGoldenVoice.value;
      final showGoldenGlow = rewardedController.showGoldenGlow.value;
      final listeningProgress = controller.listeningProgress.value;
      final speakingProgress = controller.speakingProgress.value;
      final showLottie = controller.showLottieAnimation.value;

      return GestureDetector(
        onTapDown: (_) => controller.onMicPressed(),
        onTapUp: (_) => controller.onMicReleased(),
        onTapCancel: () => controller.onMicReleased(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular progress for listening (60s max)
            if (isListening && listeningProgress > 0)
              SizedBox(
                width: 160.w,
                height: 160.w,
                child: CircularProgressIndicator(
                  value: listeningProgress,
                  strokeWidth: 4.w,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF6B4FBB).withOpacity(0.8),
                  ),
                ),
              ),

            // Circular progress for speaking (60s max)
            if (isSpeaking && speakingProgress > 0)
              SizedBox(
                width: 160.w,
                height: 160.w,
                child: CircularProgressIndicator(
                  value: speakingProgress,
                  strokeWidth: 4.w,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF4A90E2).withOpacity(0.8),
                  ),
                ),
              ),

            // Main mic button
            _BreathingMicButton(
              isListening: isListening,
              isActive: isActive,
              isGolden: isGolden,
              showLottie: showLottie,
            ),
          ],
        ),
      );
    });
  }

  // Superpower bottom sheet - elegant, slides up after shift
  Widget _buildSuperpowerBottomSheet() {
    final adFreeController = Get.find<AdFreeController>();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
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
                      const Color(0xFF1a1030).withOpacity(0.95), // Dark translucent
                      const Color(0xFF0d0618).withOpacity(0.98),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Superpower cards
                      Obx(() {
                        final rewardedController = Get.find<RewardedController>();
                        final isGolden = rewardedController.hasGoldenVoice.value;
                        final isAdFree = adFreeController.isAdFree.value;

                        return Column(
                          children: [
                            _buildSuperpowerCard(
                              '2× Stronger!', // UNLIMITED - always available!
                              Icons.bolt_outlined,
                              controller.onMakeStronger, // Always enabled
                              isActive: false, // Never disabled
                            ),
                            SizedBox(height: 12.h),
                            _buildSuperpowerCard(
                              isGolden
                                  ? 'Golden • ${rewardedController.goldenTimeRemaining.value}'
                                  : 'Golden Voice',
                              Icons.star_outline_rounded,
                              isGolden ? null : controller.onUnlockGolden,
                              isActive: isGolden,
                            ),
                            SizedBox(height: 12.h),
                            _buildSuperpowerCard(
                              isAdFree
                                  ? 'Ad-free • ${adFreeController.adFreeTimeRemaining.value}'
                                  : 'Remove ads',
                              Icons.spa_outlined,
                              isAdFree ? null : controller.onRemoveAds,
                              isActive: isAdFree,
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
  }

  // Individual superpower card - minimal, elegant
  Widget _buildSuperpowerCard(
    String text,
    IconData icon,
    VoidCallback? onTap, {
    bool isActive = false,
  }) {
    return InkWell(
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
    return Container(
      width: double.infinity,
      height: 50.h,
      color: Colors.transparent,
      child: adService.bannerAd != null
          ? AdWidget(ad: adService.bannerAd!)
          : const SizedBox.shrink(),
    );
  }

  // Habit stats widget - shows streak, today's shifts, total shifts, active days
  Widget _buildHabitStats() {
    return Container(
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
          // Day X with fire emoji (big)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Day ${HabitService.streak}',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              if (HabitService.streak >= 3) ...[
                SizedBox(width: 8.w),
                Text(
                  '🔥',
                  style: TextStyle(fontSize: 24.sp),
                ),
              ],
            ],
          ),

          SizedBox(height: 8.h),

          // Today's shifts
          Text(
            'Today: ${HabitService.todayShifts} shift${HabitService.todayShifts == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 13.sp,
              color: const Color(0xFF9B7FDB).withOpacity(0.8),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),

          SizedBox(height: 4.h),

          // Total shifts and active days
          Text(
            'Total: ${HabitService.totalShifts} shifts • ${HabitService.activeDays} active day${HabitService.activeDays == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// Separate StatefulWidget for breathing animation to avoid TweenAnimationBuilder issues
class _BreathingMicButton extends StatefulWidget {
  final bool isListening;
  final bool isActive;
  final bool isGolden;
  final bool showLottie;

  const _BreathingMicButton({
    required this.isListening,
    required this.isActive,
    required this.isGolden,
    this.showLottie = false,
  });

  @override
  State<_BreathingMicButton> createState() => _BreathingMicButtonState();
}

class _BreathingMicButtonState extends State<_BreathingMicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isListening ? 1.0 : _scaleAnimation.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background container with gradient and glow
              Container(
                width: 140.w,
                height: 140.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: widget.isGolden
                        ? [
                            const Color(0xFFD4AF37).withOpacity(0.9), // Soft gold
                            const Color(0xFFB8941E).withOpacity(0.8),
                          ]
                        : widget.isListening
                            ? [
                                const Color(0xFF6B4FBB).withOpacity(0.9), // Soft purple
                                const Color(0xFF4A3580).withOpacity(0.8),
                              ]
                            : [
                                const Color(0xFF5A4A8A).withOpacity(0.7), // Very soft purple
                                const Color(0xFF3D2F5F).withOpacity(0.6),
                              ],
                  ),
                  boxShadow: [
                    // Soft outer glow
                    BoxShadow(
                      color: widget.isGolden
                          ? const Color(0xFFD4AF37).withOpacity(0.15)
                          : const Color(0xFF6B4FBB).withOpacity(0.12),
                      blurRadius: widget.isGolden ? 40 : 30,
                      spreadRadius: widget.isGolden ? 8 : 5,
                    ),
                    // Inner subtle glow
                    BoxShadow(
                      color: widget.isGolden
                          ? const Color(0xFFFFE082).withOpacity(0.1)
                          : const Color(0xFF9B7FDB).withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Golden Voice looping sparkle overlay (subtle, always on during Golden mode)
              if (widget.isGolden)
                Positioned.fill(
                  child: SizedBox(
                    width: 160.w,
                    height: 160.w,
                    child: Lottie.asset(
                      'assets/animations/sparkle.json',
                      repeat: true,
                      animate: true,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to subtle golden ring if Lottie fails
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              // Lottie animation overlay when showing animation or listening
              if (widget.showLottie || widget.isListening)
                SizedBox(
                  width: 100.w,
                  height: 100.w,
                  child: Lottie.asset(
                    'assets/animations/microphone_pulse.json',
                    repeat: true,
                    animate: true,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to icon if Lottie fails to load
                      return Icon(
                        Icons.mic,
                        size: 48.sp,
                        color: Colors.white.withOpacity(0.95),
                      );
                    },
                  ),
                )
              else
                Icon(
                  widget.isActive ? Icons.mic : Icons.mic_none_rounded,
                  size: 48.sp,
                  color: Colors.white.withOpacity(0.95),
                ),
            ],
          ),
        );
      },
    );
  }
}
