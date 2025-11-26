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
import 'app/controllers/ad_free_controller.dart';
import 'app/controllers/streak_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dotenv (load environment variables)
  try {
    await dotenv.load(fileName: ".env");
    print('✅ [INIT] Environment variables loaded');
  } catch (e) {
    print('❌ [INIT] Error loading .env file: $e');
    // Continue without .env - app will use default values
  }

  // Initialize Firebase (check if already initialized to prevent duplicate app error)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ [INIT] Firebase initialized');
  } catch (e, stackTrace) {
    if (e.toString().contains('duplicate-app')) {
      // Firebase already initialized, continue
      print('✅ [INIT] Firebase already initialized');
    } else {
      // Critical error - Firebase is required
      print('❌ [INIT] Fatal error initializing Firebase: $e');
      print('❌ [INIT] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ========== FIREBASE CRASHLYTICS SETUP (RELEASE MODE ONLY) ==========
  // Only activate Crashlytics in release builds to avoid noise during development
  if (kReleaseMode) {
    try {
      // Pass all uncaught Flutter errors to Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Pass all uncaught asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      print('🔥 [CRASHLYTICS] Activated in release mode');
    } catch (e) {
      print('❌ [CRASHLYTICS] Error setting up Crashlytics: $e');
      // Continue without Crashlytics - app should still work
    }
  } else {
    print('🔥 [CRASHLYTICS] Disabled in debug mode');
  }

  // Initialize GetStorage
  try {
    await GetStorage.init();
    print('✅ [INIT] GetStorage initialized');
  } catch (e, stackTrace) {
    print('❌ [INIT] Error initializing GetStorage: $e');
    print('❌ [INIT] Stack trace: $stackTrace');
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'GetStorage initialization failed',
        fatal: true,
      );
    }
    rethrow; // GetStorage is critical
  }

  // Initialize Mobile Ads
  try {
    await MobileAds.instance.initialize();
    print('✅ [INIT] Mobile Ads initialized');
  } catch (e, stackTrace) {
    print('❌ [INIT] Error initializing Mobile Ads: $e');
    print('❌ [INIT] Stack trace: $stackTrace');
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Mobile Ads initialization failed',
        fatal: false, // Non-fatal - app can work without ads
      );
    }
    // Continue without ads - app should still work
  }

  // Initialize Services
  try {
    await Get.putAsync(() => StorageService().init());
    print('✅ [INIT] StorageService initialized');

    // Apply crash reports setting from storage
    final storage = Get.find<StorageService>();
    final crashReportsEnabled = storage.getCrashReportsEnabled();
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(crashReportsEnabled);
    print('🔥 [CRASHLYTICS] Collection ${crashReportsEnabled ? 'enabled' : 'disabled'} from user preference');
  } catch (e, stackTrace) {
    print('❌ [INIT] Error initializing StorageService: $e');
    print('❌ [INIT] Stack trace: $stackTrace');
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'StorageService initialization failed',
        fatal: true,
      );
    }
    rethrow; // StorageService is critical
  }

  // Initialize HabitService (handles notifications + streak tracking)
  try {
    await Get.putAsync(() => HabitService().init());
    print('✅ [INIT] HabitService initialized');
  } catch (e, stackTrace) {
    print('❌ [INIT] Error initializing HabitService: $e');
    print('❌ [INIT] Stack trace: $stackTrace');
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'HabitService initialization failed',
        fatal: false, // Non-fatal - app can work without habits
      );
    }
    // Continue without HabitService - app should still work
  }

  // Initialize RemoteConfig (await to ensure it's ready before app starts)
  try {
    await Get.putAsync(() => RemoteConfigService().init());
    print('✅ [INIT] RemoteConfigService initialized');
  } catch (e, stackTrace) {
    print('❌ [INIT] Error initializing RemoteConfigService: $e');
    print('❌ [INIT] Stack trace: $stackTrace');
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'RemoteConfigService initialization failed',
        fatal: false, // Non-fatal - app can work without remote config
      );
    }
    // Continue without RemoteConfig - app should still work
  }

  // Initialize AdService
  try {
    Get.put(AdService());
    print('✅ [INIT] AdService initialized');
  } catch (e, stackTrace) {
    print('❌ [INIT] Error initializing AdService: $e');
    print('❌ [INIT] Stack trace: $stackTrace');
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'AdService initialization failed',
        fatal: false, // Non-fatal - app can work without ads
      );
    }
    // Continue without AdService - app should still work
  }

  // Initialize AdFreeController
  try {
    Get.put(AdFreeController());
    print('✅ [INIT] AdFreeController initialized');
  } catch (e, stackTrace) {
    print('❌ [INIT] Error initializing AdFreeController: $e');
    print('❌ [INIT] Stack trace: $stackTrace');
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'AdFreeController initialization failed',
        fatal: false,
      );
    }
    // Continue without AdFreeController
  }

  // Initialize StreakController
  try {
    Get.put(StreakController());
    print('✅ [INIT] StreakController initialized');
  } catch (e, stackTrace) {
    print('❌ [INIT] Error initializing StreakController: $e');
    print('❌ [INIT] Stack trace: $stackTrace');
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'StreakController initialization failed',
        fatal: false,
      );
    }
    // Continue without StreakController
  }

  // Initialize CrashlyticsService (must be after StorageService)
  try {
    Get.put(CrashlyticsService());
    print('✅ [INIT] CrashlyticsService initialized');
  } catch (e, stackTrace) {
    print('❌ [INIT] Error initializing CrashlyticsService: $e');
    print('❌ [INIT] Stack trace: $stackTrace');
    // Can't report to Crashlytics if CrashlyticsService failed to initialize
    // Continue without CrashlyticsService
  }

  // Initialize PermissionService (must be after StorageService)
  try {
    Get.put(PermissionService());
    print('✅ [INIT] PermissionService initialized');
  } catch (e, stackTrace) {
    print('❌ [INIT] Error initializing PermissionService: $e');
    print('❌ [INIT] Stack trace: $stackTrace');
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'PermissionService initialization failed',
        fatal: false,
      );
    }
    // Continue without PermissionService - will fall back to old behavior
  }

  // Set portrait orientation only
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    print('✅ [INIT] Portrait orientation set');
  } catch (e, stackTrace) {
    print('❌ [INIT] Error setting orientation: $e');
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'SystemChrome orientation setup failed',
        fatal: false,
      );
    }
    // Continue - orientation is not critical
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
    print('✅ [INIT] System UI overlay style set');
  } catch (e, stackTrace) {
    print('❌ [INIT] Error setting system UI overlay: $e');
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'SystemChrome UI overlay setup failed',
        fatal: false,
      );
    }
    // Continue - UI overlay is not critical
  }

  print('🚀 [INIT] App initialization complete - launching app');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storageService = Get.find<StorageService>();
    
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
            scaffoldBackgroundColor: const Color(0xFF1a0f2e),
            fontFamily: 'Poppins',
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          translations: AppTranslations(),
          locale: storageService.getLocale(),
          fallbackLocale: const Locale('en', 'US'),
          initialRoute: AppRoutes.HOME,
          getPages: AppPages.pages,
        );
      },
    );
  }
}

