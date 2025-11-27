import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get/get.dart';
import 'home_controller.dart';
import '../../services/groq_llm_service.dart';
import '../../services/speech_service.dart';
import '../../services/polly_tts_service.dart';
import '../../controllers/rewarded_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GroqLLMService>(() {
      try {
        return GroqLLMService();
      } catch (e, stackTrace) {
        if (kReleaseMode) {
          FirebaseCrashlytics.instance.recordError(
            e,
            stackTrace,
            reason: 'GroqLLMService initialization failed in HomeBinding',
            fatal: false,
          );
        }
        rethrow;
      }
    });

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

    Get.lazyPut<PollyTTSService>(() {
      try {
        return PollyTTSService();
      } catch (e, stackTrace) {
        if (kReleaseMode) {
          FirebaseCrashlytics.instance.recordError(
            e,
            stackTrace,
            reason: 'PollyTTSService initialization failed in HomeBinding',
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
