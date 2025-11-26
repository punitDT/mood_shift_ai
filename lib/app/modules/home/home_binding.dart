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
    // Wrap each service initialization with error handling
    Get.lazyPut<GroqLLMService>(() {
      try {
        print('🔄 [BINDING] Initializing GroqLLMService...');
        return GroqLLMService();
      } catch (e, stackTrace) {
        print('❌ [BINDING] Error initializing GroqLLMService: $e');
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
        print('🔄 [BINDING] Initializing SpeechService...');
        return SpeechService();
      } catch (e, stackTrace) {
        print('❌ [BINDING] Error initializing SpeechService: $e');
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
        print('🔄 [BINDING] Initializing PollyTTSService...');
        return PollyTTSService();
      } catch (e, stackTrace) {
        print('❌ [BINDING] Error initializing PollyTTSService: $e');
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
        print('🔄 [BINDING] Initializing RewardedController...');
        return RewardedController();
      } catch (e, stackTrace) {
        print('❌ [BINDING] Error initializing RewardedController: $e');
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
        print('🔄 [BINDING] Initializing HomeController...');
        return HomeController();
      } catch (e, stackTrace) {
        print('❌ [BINDING] Error initializing HomeController: $e');
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

    print('✅ [BINDING] All home dependencies registered');
  }
}

