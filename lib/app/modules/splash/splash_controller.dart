import 'package:get/get.dart';
import '../../routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    print('SplashController onInit called');
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('SplashController _initializeApp started');
    // Wait for 2.5 seconds (splash animation)
    await Future.delayed(const Duration(milliseconds: 2500));

    print('SplashController navigating to home');
    // Remote config is already being fetched in background (from main.dart init)
    // No need to wait for it here - just navigate to home
    // Force update check will happen in HomeController if needed
    Get.offAllNamed(AppRoutes.HOME);
  }
}

