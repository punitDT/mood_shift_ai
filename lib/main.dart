import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/translations/app_translations.dart';
import 'app/services/remote_config_service.dart';
import 'app/services/ad_service.dart';
import 'app/services/storage_service.dart';
import 'app/services/habit_service.dart';
import 'app/services/crashlytics_service.dart';
import 'app/services/permission_service.dart';
import 'app/services/device_service.dart';
import 'app/services/cloud_ai_service.dart';
import 'app/services/audio_player_service.dart';
import 'app/services/in_app_review_service.dart';
import 'app/controllers/ad_free_controller.dart';
import 'app/controllers/streak_controller.dart';
import 'app/controllers/rewarded_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dotenv (load environment variables)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Continue without .env - app will use default values
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stackTrace) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  // Firebase Crashlytics setup (release mode only)
  if (kReleaseMode) {
    try {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e) {
      // Continue without Crashlytics
    }
  }

  // Initialize GetStorage
  try {
    await GetStorage.init();
  } catch (e, stackTrace) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'GetStorage initialization failed', fatal: true);
    }
    rethrow;
  }

  // Initialize Mobile Ads
  try {
    await MobileAds.instance.initialize();
  } catch (e, stackTrace) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Mobile Ads initialization failed', fatal: false);
    }
  }

  // Initialize Services
  try {
    await Get.putAsync(() => StorageService().init());
    final storage = Get.find<StorageService>();
    final crashReportsEnabled = storage.getCrashReportsEnabled();
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(crashReportsEnabled);
  } catch (e, stackTrace) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'StorageService initialization failed', fatal: true);
    }
    rethrow;
  }

  // Initialize HabitService
  try {
    await Get.putAsync(() => HabitService().init());
  } catch (e, stackTrace) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'HabitService initialization failed', fatal: false);
    }
  }

  // Initialize RemoteConfig
  try {
    await Get.putAsync(() => RemoteConfigService().init());
  } catch (e, stackTrace) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'RemoteConfigService initialization failed', fatal: false);
    }
  }

  // Initialize AdService
  try {
    Get.put(AdService());
  } catch (e, stackTrace) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'AdService initialization failed', fatal: false);
    }
  }

  // Initialize AdFreeController
  try {
    Get.put(AdFreeController());
  } catch (e, stackTrace) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'AdFreeController initialization failed', fatal: false);
    }
  }

  // Initialize StreakController
  try {
    Get.put(StreakController());
  } catch (e, stackTrace) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'StreakController initialization failed', fatal: false);
    }
  }

  // Initialize RewardedController (needed globally for HomeView)
  try {
    Get.put(RewardedController());
  } catch (e, stackTrace) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'RewardedController initialization failed', fatal: false);
    }
  }

  // Initialize CrashlyticsService
  try {
    Get.put(CrashlyticsService());
  } catch (e, stackTrace) {
    // Can't report to Crashlytics if CrashlyticsService failed
  }

  // Initialize PermissionService
  try {
    Get.put(PermissionService());
  } catch (e, stackTrace) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'PermissionService initialization failed', fatal: false);
    }
  }

  // Initialize DeviceService (for Cloud Functions device ID)
  try {
    Get.put(DeviceService());
  } catch (e, stackTrace) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'DeviceService initialization failed', fatal: false);
    }
  }

  // Initialize CloudAIService
  try {
    Get.put(CloudAIService());
  } catch (e, stackTrace) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'CloudAIService initialization failed', fatal: false);
    }
  }

  // Initialize AudioPlayerService
  try {
    Get.put(AudioPlayerService());
  } catch (e, stackTrace) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'AudioPlayerService initialization failed', fatal: false);
    }
  }

  // Initialize InAppReviewService
  try {
    await Get.putAsync(() => InAppReviewService().init());
  } catch (e, stackTrace) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'InAppReviewService initialization failed', fatal: false);
    }
  }

  // Set portrait orientation only
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e, stackTrace) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'SystemChrome orientation setup failed', fatal: false);
    }
  }

  // Set system UI overlay style
  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF1a0f2e),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  } catch (e, stackTrace) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'SystemChrome UI overlay setup failed', fatal: false);
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storageService = Get.find<StorageService>();

    // Determine initial route based on onboarding status
    final hasSeenOnboarding = storageService.hasSeenOnboarding();
    final initialRoute = hasSeenOnboarding ? AppRoutes.ONBOARDING : AppRoutes.ONBOARDING;

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'MoodShift AI',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.deepPurple,
            scaffoldBackgroundColor: const Color(0xFF0a0520),
            fontFamily: 'Poppins',
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          translations: AppTranslations(),
          locale: storageService.getLocale(),
          fallbackLocale: const Locale('en', 'US'),
          initialRoute: initialRoute,
          getPages: AppPages.pages,
        );
      },
    );
  }
}

