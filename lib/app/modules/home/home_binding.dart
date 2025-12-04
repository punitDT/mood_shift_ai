import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get/get.dart';
import 'home_controller.dart';
import '../../services/speech_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SpeechService>(() {
      try {
        return SpeechService();
      } catch (e, stackTrace) {
        if (kReleaseMode) {
          FirebaseCrashlytics.instance.recordError(
            e,
            stackTrace,
            reason: 'SpeechService initialization failed in HomeBinding',
            fatal: false,
          );
        }
        rethrow;
      }
    });

    // RewardedController is now registered globally in main.dart

    Get.lazyPut<HomeController>(() {
      try {
        return HomeController();
      } catch (e, stackTrace) {
        if (kReleaseMode) {
          FirebaseCrashlytics.instance.recordError(
            e,
            stackTrace,
            reason: 'HomeController initialization failed in HomeBinding',
            fatal: true,
          );
        }
        rethrow;
      }
    });
  }
}
