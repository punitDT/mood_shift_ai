import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../services/remote_config_service.dart';

class SplashController extends GetxController {
  final RemoteConfigService _remoteConfig = Get.find<RemoteConfigService>();

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for 2.5 seconds (splash animation)
    await Future.delayed(const Duration(milliseconds: 2500));

    // Fetch remote config
    await _remoteConfig.fetchConfig();

    // Check if force update is required
    if (_remoteConfig.shouldForceUpdate()) {
      // Force update dialog will be shown in HomeView
      // Still navigate to home
      Get.offAllNamed(AppRoutes.HOME);
    } else {
      // Navigate to home
      Get.offAllNamed(AppRoutes.HOME);
    }
  }
}

