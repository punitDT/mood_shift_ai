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

          // 2× STRONGER Electric Purple Flash Effect
          Obx(() => rewardedController.showStrongerFlash.value
              ? Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: const Color(0xFF9D7FFF).withOpacity(0.3), // Electric purple
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
                    // Top Banner Ad (only if loaded and not ad-free)
                    Obx(() => adService.isTopBannerLoaded.value
                        ? _buildTopBannerAd(adService)
                        : const SizedBox.shrink()),

                    // Top Bar (minimal)
                    _buildMinimalTopBar(),

                    // Spacer - creates the 70-80% empty space
                    const Spacer(flex: 1),

                    // Instructional text above mic button
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25.w),
                      child: Column(
                        children: [
                          Text(
                            'mic_instruction_line1'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'mic_instruction_line2'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3,
                              height: 1.4,
                            ),
                          ),
                        ],
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
                Color(0xFF8B7FDB), // Light purple
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
    final rewardedController = Get.find<RewardedController>();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
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

  // Premium mic button - elegant, soft glow, breathing animation
  Widget _buildPremiumMicButton() {
    final rewardedController = Get.find<RewardedController>();

    return Obx(() {
      final isActive = controller.currentState.value != AppState.idle;
      final isListening = controller.currentState.value == AppState.listening;
      final isSpeaking = controller.currentState.value == AppState.speaking;
      final isGolden = rewardedController.hasGoldenVoice.value;

      return GestureDetector(
        onTapDown: (_) => controller.onMicPressed(),
        onTapUp: (_) => controller.onMicReleased(),
        onTapCancel: () => controller.onMicReleased(),
        child: _BreathingMicButton(
          isListening: isListening,
          isSpeaking: isSpeaking,
          isActive: isActive,
          isGolden: isGolden,
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

  Widget _buildTopBannerAd(AdService adService) {
    return Container(
      width: double.infinity,
      height: 50.h,
      color: Colors.transparent,
      child: adService.topBannerAd != null
          ? AdWidget(ad: adService.topBannerAd!)
          : const SizedBox.shrink(),
    );
  }

  // Habit stats widget - shows streak, today's shifts, total shifts, active days
  Widget _buildHabitStats() {
    final streakController = Get.find<StreakController>();

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
          // Day X with fire emoji (big)
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
            'Total: ${streakController.totalShifts.value} shifts • ${HabitService.activeDays} active day${HabitService.activeDays == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    ));
  }
}

// Premium press-and-hold mic button with beautiful animations
class _BreathingMicButton extends StatefulWidget {
  final bool isListening;
  final bool isSpeaking;
  final bool isActive;
  final bool isGolden;

  const _BreathingMicButton({
    required this.isListening,
    required this.isSpeaking,
    required this.isActive,
    required this.isGolden,
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

    // Start/stop pulse animation based on listening or speaking state
    if ((widget.isListening || widget.isSpeaking) &&
        !(oldWidget.isListening || oldWidget.isSpeaking)) {
      _pulseController.repeat(reverse: true);
    } else if (!(widget.isListening || widget.isSpeaking) &&
               (oldWidget.isListening || oldWidget.isSpeaking)) {
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
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 130.w,
                            height: 130.w,
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
                        return Transform.scale(
                          scale: 1.0 + (_pulseAnimation.value - 1.0) * 0.6,
                          child: Container(
                            width: 120.w,
                            height: 120.w,
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
                    _WaveRing(size: 140.w, delay: 0),
                    _WaveRing(size: 120.w, delay: 300),
                    _WaveRing(size: 100.w, delay: 600),
                  ],

                  // Main button with size animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: (widget.isListening || widget.isSpeaking) ? 110.w : 86.w,
                    height: (widget.isListening || widget.isSpeaking) ? 110.w : 86.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isGolden
                          ? const Color(0xFFD4AF37)
                          : Colors.white,
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
                        if (widget.isGolden)
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                      ],
                    ),
                    child: Center(
                      child: _buildMicIcon(),
                    ),
                  ),

                  // Golden Voice sparkle overlay
                  if (widget.isGolden)
                    SizedBox(
                      width: (widget.isListening || widget.isSpeaking) ? 130.w : 106.w,
                      height: (widget.isListening || widget.isSpeaking) ? 130.w : 106.w,
                      child: Lottie.asset(
                        'assets/animations/sparkle.json',
                        repeat: true,
                        animate: true,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        // "Recording..." or "Speaking..." text
        AnimatedOpacity(
          opacity: (widget.isListening || widget.isSpeaking) ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: (widget.isListening || widget.isSpeaking) ? 30.h : 0,
            child: (widget.isListening || widget.isSpeaking)
                ? Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          child: Text(
                            widget.isListening ? 'Recording' : 'Speaking',
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
    if (widget.isListening) {
      // Show mic_none with subtle sound wave animation
      return Stack(
        alignment: Alignment.center,
        children: [
          // Sound wave bars (left and right)
          // Positioned(
          //   left: 20.w,
          //   child: _SoundWaveBar(delay: 0),
          // ),
          // Positioned(
          //   right: 20.w,
          //   child: _SoundWaveBar(delay: 200),
          // ),
          // Mic icon
          Icon(
            Icons.mic_none_rounded,
            size: 40.sp,
            color: widget.isGolden
                ? Colors.white
                : const Color(0xFF1E1E3F),
          ),
        ],
      );
    } else if (widget.isSpeaking) {
      // Show volume icon with wavy bars when Polly is speaking
      return Stack(
        alignment: Alignment.center,
        children: [
          // Wavy sound bars around the icon
          // Positioned(
          //   left: 15.w,
          //   child: _SpeakingWaveBar(index: 0),
          // ),
          // Positioned(
          //   left: 22.w,
          //   child: _SpeakingWaveBar(index: 1),
          // ),
          // Positioned(
          //   right: 15.w,
          //   child: _SpeakingWaveBar(index: 2),
          // ),
          // Positioned(
          //   right: 22.w,
          //   child: _SpeakingWaveBar(index: 3),
          // ),
          // Volume icon
          Icon(
            Icons.volume_up_rounded,
            size: 40.sp,
            color: widget.isGolden
                ? Colors.white
                : const Color(0xFF1E1E3F),
          ),
        ],
      );
    } else {
      // Idle state - simple mic icon
      return Icon(
        Icons.mic_none_rounded,
        size: 36.sp,
        color: widget.isGolden
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

