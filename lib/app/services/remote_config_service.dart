import 'package:get/get.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class RemoteConfigService extends GetxService {
  late final FirebaseRemoteConfig _remoteConfig;
  
  final forceUpdate = false.obs;
  final latestVersion = ''.obs;
  final updateMessage = ''.obs;

  Future<RemoteConfigService> init() async {
    _remoteConfig = FirebaseRemoteConfig.instance;

    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 1),
      ),
    );

    await _remoteConfig.setDefaults({
      'force_update': false,
      'latest_version': '1.0.0',
      'update_message': 'A new version is available. Please update to continue using the app.',
    });

    // Fetch config in background without blocking app startup
    fetchConfig();

    return this;
  }

  Future<void> fetchConfig() async {
    try {
      await _remoteConfig.fetchAndActivate();
      
      forceUpdate.value = _remoteConfig.getBool('force_update');
      latestVersion.value = _remoteConfig.getString('latest_version');
      updateMessage.value = _remoteConfig.getString('update_message');
      
      // Check if update is needed
      if (forceUpdate.value) {
        await _checkVersion();
      }
    } catch (e) {
      print('Error fetching remote config: $e');
    }
  }

  Future<void> _checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      if (_isVersionLower(currentVersion, latestVersion.value)) {
        // Force update is needed
        forceUpdate.value = true;
      } else {
        forceUpdate.value = false;
      }
    } catch (e) {
      print('Error checking version: $e');
    }
  }

  bool _isVersionLower(String current, String latest) {
    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      if (currentParts[i] < latestParts[i]) return true;
      if (currentParts[i] > latestParts[i]) return false;
    }
    
    return false;
  }

  bool shouldForceUpdate() {
    return forceUpdate.value;
  }

  String getUpdateMessage() {
    return updateMessage.value;
  }
}

