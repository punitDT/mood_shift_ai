import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../services/storage_service.dart';
import '../../routes/app_routes.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  static const Color _primaryPurple = Color(0xFF7B5EBF);
  static const Color _lightPurple = Color(0xFFB39DDB);

  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      icon: _GentleLightAnimation(),
      title: 'Welcome to MoodShift',
      subtitle: 'Your pocket friend who always listens',
    ),
    _OnboardingSlide(
      icon: _SpeechBubbleAnimation(),
      title: 'Just talk. No typing.',
      subtitle: 'Hold and speak for up to 1 minute — we\'ll hear everything',
    ),
    _OnboardingSlide(
      icon: _BloomingFlowerAnimation(),
      title: 'Feel better in seconds',
      subtitle: 'We\'ll gently shift your mood with kindness and understanding',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Column(
            children: [
              // Skip button at top right
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16.sp,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
              // PageView for slides
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildSlide(_slides[index]);
                  },
                ),
              ),
              // Page indicators
              Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => _buildDotIndicator(index),
                  ),
                ),
              ),
              // Bottom button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: _currentPage == _slides.length - 1
                        ? _completeOnboarding
                        : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == _slides.length - 1 ? 'Start Talking' : 'Next',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDotIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      width: _currentPage == index ? 24.w : 8.w,
      height: 8.w,
      decoration: BoxDecoration(
        color: _currentPage == index ? _lightPurple : _lightPurple.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }

  Widget _buildSlide(_OnboardingSlide slide) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 220.w,
            height: 220.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _lightPurple.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: slide.icon,
          ),
          SizedBox(height: 50.h),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
              height: 1.2,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white70,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _completeOnboarding() {

    final storageService = Get.find<StorageService>();
    storageService.setSeenOnboarding(true);
    Get.offAllNamed(AppRoutes.HOME);
  }
}

class _OnboardingSlide {
  final Widget icon;
  final String title;
  final String subtitle;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

// Slide 1: Gentle glowing light with particles animation
class _GentleLightAnimation extends StatefulWidget {
  const _GentleLightAnimation();

  @override
  State<_GentleLightAnimation> createState() => _GentleLightAnimationState();
}

class _GentleLightAnimationState extends State<_GentleLightAnimation>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _particleController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowController, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(220.w, 220.w),
          painter: _GentleLightPainter(
            glowProgress: _glowController.value,
            particleProgress: _particleController.value,
          ),
        );
      },
    );
  }
}

class _GentleLightPainter extends CustomPainter {
  final double glowProgress;
  final double particleProgress;

  _GentleLightPainter({
    required this.glowProgress,
    required this.particleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseUnit = size.width / 220; // Scale factor based on 220 as reference

    // Outer soft glow rings
    for (int i = 3; i >= 0; i--) {
      final ringRadius = (50.0 + (i * 25) + (glowProgress * 10)) * baseUnit;
      final ringPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFB39DDB).withValues(alpha: 0.3 - (i * 0.07)),
            const Color(0xFF9575CD).withValues(alpha: 0.1 - (i * 0.02)),
            const Color(0xFF7B5EBF).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: ringRadius));
      canvas.drawCircle(center, ringRadius, ringPaint);
    }

    // Central glowing orb
    final orbRadius = (40 + (glowProgress * 8)) * baseUnit;
    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.95),
          const Color(0xFFE1BEE7).withValues(alpha: 0.8),
          const Color(0xFFCE93D8).withValues(alpha: 0.6),
          const Color(0xFFBA68C8).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: orbRadius));
    canvas.drawCircle(center, orbRadius, orbPaint);

    // Floating particles around the orb
    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 12; i++) {
      final angle = (i * math.pi * 2 / 12) + (particleProgress * math.pi * 2);
      final distance = (65 + math.sin(particleProgress * math.pi * 2 + i) * 15) * baseUnit;
      final particleX = center.dx + math.cos(angle) * distance;
      final particleY = center.dy + math.sin(angle) * distance;
      final particleSize = (3.0 + math.sin(particleProgress * math.pi * 4 + i * 0.5) * 2) * baseUnit;

      particlePaint.shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.9),
          const Color(0xFFE1BEE7).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(particleX, particleY), radius: particleSize + 3 * baseUnit));

      canvas.drawCircle(Offset(particleX, particleY), particleSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GentleLightPainter oldDelegate) => true;
}

// Slide 2: Speech bubble with voice lines animation
class _SpeechBubbleAnimation extends StatefulWidget {
  const _SpeechBubbleAnimation();

  @override
  State<_SpeechBubbleAnimation> createState() => _SpeechBubbleAnimationState();
}

class _SpeechBubbleAnimationState extends State<_SpeechBubbleAnimation>
    with TickerProviderStateMixin {
  late AnimationController _bubbleController;
  late AnimationController _linesController;

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _linesController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    _linesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bubbleController, _linesController]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(220.w, 220.w),
          painter: _SpeechBubblePainter(
            bubbleProgress: _bubbleController.value,
            linesProgress: _linesController.value,
          ),
        );
      },
    );
  }
}

class _SpeechBubblePainter extends CustomPainter {
  final double bubbleProgress;
  final double linesProgress;

  _SpeechBubblePainter({
    required this.bubbleProgress,
    required this.linesProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseUnit = size.width / 220; // Scale factor based on 220 as reference

    // Speech bubble
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - 10 * baseUnit),
        width: 140 * baseUnit,
        height: 100 * baseUnit,
      ),
      Radius.circular(25 * baseUnit),
    );

    final bubblePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF9575CD), Color(0xFF7B5EBF)],
      ).createShader(bubbleRect.outerRect);

    canvas.drawRRect(bubbleRect, bubblePaint);

    // Bubble tail
    final tailPath = Path()
      ..moveTo(center.dx - 15 * baseUnit, center.dy + 40 * baseUnit)
      ..lineTo(center.dx - 30 * baseUnit, center.dy + 70 * baseUnit)
      ..lineTo(center.dx + 5 * baseUnit, center.dy + 40 * baseUnit)
      ..close();
    canvas.drawPath(tailPath, bubblePaint);

    // Voice lines inside bubble
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4 * baseUnit
      ..strokeCap = StrokeCap.round;

    const lineHeights = [0.3, 0.7, 0.5, 0.9, 0.4];
    final baseY = center.dy - 10 * baseUnit;

    for (int i = 0; i < 5; i++) {
      final phase = (linesProgress + i * 0.2) % 1.0;
      final height = (15 + (math.sin(phase * math.pi * 2) * 0.5 + 0.5) * lineHeights[i] * 25) * baseUnit;
      final x = center.dx - 50 * baseUnit + (i * 25 * baseUnit);

      canvas.drawLine(
        Offset(x, baseY - height / 2),
        Offset(x, baseY + height / 2),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) => true;
}

// Slide 3: Blooming flower animation
class _BloomingFlowerAnimation extends StatefulWidget {
  const _BloomingFlowerAnimation();

  @override
  State<_BloomingFlowerAnimation> createState() => _BloomingFlowerAnimationState();
}

class _BloomingFlowerAnimationState extends State<_BloomingFlowerAnimation>
    with TickerProviderStateMixin {
  late AnimationController _bloomController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _bloomController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bloomController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bloomController, _glowController]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(220.w, 220.w),
          painter: _BloomingFlowerPainter(
            bloomProgress: _bloomController.value,
            glowProgress: _glowController.value,
          ),
        );
      },
    );
  }
}

class _BloomingFlowerPainter extends CustomPainter {
  final double bloomProgress;
  final double glowProgress;

  _BloomingFlowerPainter({
    required this.bloomProgress,
    required this.glowProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseUnit = size.width / 220; // Scale factor based on 220 as reference

    // Outer glow
    final glowRadius = (70 + (glowProgress * 20)) * baseUnit;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFCE93D8).withValues(alpha: 0.4),
          const Color(0xFFB39DDB).withValues(alpha: 0.2),
          const Color(0xFF9575CD).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
    canvas.drawCircle(center, glowRadius, glowPaint);

    // Petals
    const petalCount = 8;
    final petalScale = 0.8 + (bloomProgress * 0.2);

    for (int i = 0; i < petalCount; i++) {
      final angle = (i * 2 * math.pi / petalCount) + (bloomProgress * 0.3);
      final petalLength = 55 * petalScale * baseUnit;
      final petalWidth = 28 * petalScale * baseUnit;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final petalPath = Path();
      petalPath.moveTo(0, 0);
      petalPath.quadraticBezierTo(petalWidth, -petalLength * 0.5, 0, -petalLength);
      petalPath.quadraticBezierTo(-petalWidth, -petalLength * 0.5, 0, 0);

      final petalPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(const Color(0xFFE1BEE7), const Color(0xFFCE93D8), bloomProgress)!,
            Color.lerp(const Color(0xFFBA68C8), const Color(0xFF9C27B0), bloomProgress)!,
          ],
        ).createShader(Rect.fromCenter(center: Offset.zero, width: petalWidth * 2, height: petalLength));

      canvas.drawPath(petalPath, petalPaint);
      canvas.restore();
    }

    // Center of flower
    final centerRadius = 22 * baseUnit;
    final centerPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFE082), Color(0xFFFFB74D), Color(0xFFFFA726)],
      ).createShader(Rect.fromCircle(center: center, radius: centerRadius));
    canvas.drawCircle(center, centerRadius, centerPaint);

    // Inner glow on center
    final innerGlowRadius = 12 * baseUnit;
    final innerGlowOffset = 5 * baseUnit;
    final innerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(center.dx - innerGlowOffset, center.dy - innerGlowOffset), radius: innerGlowRadius));
    canvas.drawCircle(Offset(center.dx - innerGlowOffset, center.dy - innerGlowOffset), innerGlowRadius, innerGlowPaint);
  }

  @override
  bool shouldRepaint(covariant _BloomingFlowerPainter oldDelegate) => true;
}
