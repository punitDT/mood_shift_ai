import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/translations/app_translations.dart';
import 'app/services/remote_config_service.dart';
import 'app/services/ad_service.dart';
import 'app/services/storage_service.dart';
import 'app/controllers/ad_free_controller.dart';
import 'app/controllers/streak_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Initialize GetStorage
  await GetStorage.init();
  
  // Initialize Mobile Ads
  await MobileAds.instance.initialize();
  
  // Initialize Services
  await Get.putAsync(() => StorageService().init());
  // Initialize RemoteConfig in background without blocking app startup
  Get.putAsync(() => RemoteConfigService().init());
  Get.put(AdService());
  Get.put(AdFreeController());
  Get.put(StreakController());
  
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
          initialRoute: AppRoutes.SPLASH,
          getPages: AppPages.pages,
        );
      },
    );
  }
}

