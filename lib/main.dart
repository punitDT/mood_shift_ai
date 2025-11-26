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
import 'app/controllers/ad_free_controller.dart';
import 'app/controllers/streak_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dotenv (load environment variables)
  await dotenv.load(fileName: ".env");

  // Initialize Firebase (check if already initialized to prevent duplicate app error)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // Firebase already initialized, continue
      print('Firebase already initialized');
    } else {
      // Re-throw other errors
      rethrow;
    }
  }

  // ========== FIREBASE CRASHLYTICS SETUP (RELEASE MODE ONLY) ==========
  // Only activate Crashlytics in release builds to avoid noise during development
  if (kReleaseMode) {
    // Pass all uncaught Flutter errors to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    print('🔥 [CRASHLYTICS] Activated in release mode');
  } else {
    print('🔥 [CRASHLYTICS] Disabled in debug mode');
  }

  // Initialize GetStorage
  await GetStorage.init();

  // Initialize Mobile Ads
  await MobileAds.instance.initialize();

  // Initialize Services
  await Get.putAsync(() => StorageService().init());
  // Initialize HabitService (handles notifications + streak tracking)
  await Get.putAsync(() => HabitService().init());
  // Initialize RemoteConfig (await to ensure it's ready before app starts)
  await Get.putAsync(() => RemoteConfigService().init());
  Get.put(AdService());
  Get.put(AdFreeController());
  Get.put(StreakController());

  // Initialize CrashlyticsService (must be after StorageService)
  Get.put(CrashlyticsService());

  // Set portrait orientation only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1a0f2e),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
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

