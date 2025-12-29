import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'storage_service.dart';
import '../utils/app_logger.dart';

/// Service to manage feature walkthrough tutorial for first-time users
/// Shows coach marks for main features: mic button, 2x stronger, crystal voice, and peace mode
class TutorialService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();

  TutorialCoachMark? _tutorialCoachMark;

  Future<TutorialService> init() async {
    AppLogger.info('📚 TutorialService initialized');
    return this;
  }

  /// Check if user has seen the main mic tutorial
  bool get hasSeenTutorial => _storage.hasSeenFeatureTutorial();

  /// Check if user has seen the features tutorial (bottom sheet)
  bool get hasSeenFeaturesTutorial => _storage.getBool('seenFeaturesTutorial') ?? false;

  /// Mark main tutorial as seen
  void markTutorialAsSeen() {
    _storage.setSeenFeatureTutorial(true);
    AppLogger.info('📚 Main tutorial marked as seen');
  }

  /// Mark features tutorial as seen
  void markFeaturesTutorialAsSeen() {
    _storage.setBool('seenFeaturesTutorial', true);
    AppLogger.info('📚 Features tutorial marked as seen');
  }

  /// Show the main mic button tutorial (on first launch)
  void showTutorial({
    required GlobalKey micButtonKey,
    required BuildContext context,
  }) {
    if (hasSeenTutorial) {
      AppLogger.debug('📚 Main tutorial already seen, skipping');
      return;
    }

    final targets = [
      TargetFocus(
        identify: "micButton",
        keyTarget: micButtonKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.Circle,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTutorialContent(
                title: 'tutorial_mic_title'.tr,
                description: 'tutorial_mic_desc'.tr,
                icon: Icons.mic,
                color: const Color(0xFF7B5EBF),
              );
            },
          ),
        ],
      ),
    ];

    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF0a0520),
      paddingFocus: 10,
      opacityShadow: 0.8,
      hideSkip: false,
      onFinish: () {
        markTutorialAsSeen();
        AppLogger.info('📚 Main tutorial completed');
      },
      onSkip: () {
        markTutorialAsSeen();
        AppLogger.info('📚 Main tutorial skipped');
        return true;
      },
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      _tutorialCoachMark?.show(context: context);
    });
  }

  /// Show the features tutorial (after first shift when bottom sheet appears)
  void showFeaturesTutorial({
    required GlobalKey strongerButtonKey,
    required GlobalKey crystalButtonKey,
    required GlobalKey peaceModeButtonKey,
    required BuildContext context,
  }) {
    if (hasSeenFeaturesTutorial) {
      AppLogger.debug('📚 Features tutorial already seen, skipping');
      return;
    }

    final targets = _createFeatureTargets(
      strongerButtonKey: strongerButtonKey,
      crystalButtonKey: crystalButtonKey,
      peaceModeButtonKey: peaceModeButtonKey,
    );

    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF0a0520),
      paddingFocus: 10,
      opacityShadow: 0.8,
      hideSkip: false,
      onFinish: () {
        markFeaturesTutorialAsSeen();
        AppLogger.info('📚 Features tutorial completed');
      },
      onSkip: () {
        markFeaturesTutorialAsSeen();
        AppLogger.info('📚 Features tutorial skipped');
        return true;
      },
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      _tutorialCoachMark?.show(context: context);
    });
  }

  /// Create tutorial targets for feature buttons (bottom sheet)
  List<TargetFocus> _createFeatureTargets({
    required GlobalKey strongerButtonKey,
    required GlobalKey crystalButtonKey,
    required GlobalKey peaceModeButtonKey,
  }) {
    return [
      // 1. 2x Stronger button
      TargetFocus(
        identify: "strongerButton",
        keyTarget: strongerButtonKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTutorialContent(
                title: 'tutorial_stronger_title'.tr,
                description: 'tutorial_stronger_desc'.tr,
                icon: Icons.bolt,
                color: const Color(0xFF7C4DFF),
              );
            },
          ),
        ],
      ),

      // 2. Crystal Voice button
      TargetFocus(
        identify: "crystalButton",
        keyTarget: crystalButtonKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTutorialContent(
                title: 'tutorial_crystal_title'.tr,
                description: 'tutorial_crystal_desc'.tr,
                icon: Icons.diamond,
                color: const Color(0xFF7B1FA2),
              );
            },
          ),
        ],
      ),

      // 3. Peace Mode button
      TargetFocus(
        identify: "peaceModeButton",
        keyTarget: peaceModeButtonKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTutorialContent(
                title: 'tutorial_peace_title'.tr,
                description: 'tutorial_peace_desc'.tr,
                icon: Icons.spa,
                color: const Color(0xFF4CAF50),
              );
            },
          ),
        ],
      ),
    ];
  }



  /// Build tutorial content widget
  Widget _buildTutorialContent({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1a0f2e),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'Poppins',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    _tutorialCoachMark = null;
    super.onClose();
  }
}
