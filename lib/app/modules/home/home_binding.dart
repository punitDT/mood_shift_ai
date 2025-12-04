import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get/get.dart';
import 'home_controller.dart';
import '../../services/speech_service.dart';
import '../../controllers/rewarded_controller.dart';

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

    Get.lazyPut<RewardedController>(() {
      try {
        return RewardedController();
      } catch (e, stackTrace) {
        if (kReleaseMode) {
          FirebaseCrashlytics.instance.recordError(
            e,
            stackTrace,
            reason: 'RewardedController initialization failed in HomeBinding',
            fatal: false,
          );
        }
        rethrow;
      }
    });

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
