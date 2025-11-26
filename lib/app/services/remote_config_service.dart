import 'package:get/get.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RemoteConfigService extends GetxService {
  late final FirebaseRemoteConfig _remoteConfig;

  final forceUpdate = false.obs;
  final latestVersion = ''.obs;
  final updateMessage = ''.obs;
  final updateAvailable = false.obs; // Tracks if any update is available (force or optional)

  Future<RemoteConfigService> init() async {
    _remoteConfig = FirebaseRemoteConfig.instance;

    final fetchTimeoutSeconds = int.tryParse(dotenv.env['REMOTE_CONFIG_FETCH_TIMEOUT_SECONDS'] ?? '10') ?? 10;
    final minimumFetchIntervalMinutes = int.tryParse(dotenv.env['REMOTE_CONFIG_MINIMUM_FETCH_INTERVAL_MINUTES'] ?? '1') ?? 1;
    final defaultForceUpdate = dotenv.env['REMOTE_CONFIG_DEFAULT_FORCE_UPDATE']?.toLowerCase() == 'true';
    final defaultLatestVersion = dotenv.env['REMOTE_CONFIG_DEFAULT_LATEST_VERSION'] ?? '1.0.0';
    final defaultUpdateMessage = dotenv.env['REMOTE_CONFIG_DEFAULT_UPDATE_MESSAGE'] ?? 'A new version is available. Please update to continue using the app.';

    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: Duration(seconds: fetchTimeoutSeconds),
        minimumFetchInterval: Duration(minutes: minimumFetchIntervalMinutes),
      ),
    );

    await _remoteConfig.setDefaults({
      'force_update': defaultForceUpdate,
      'latest_version': defaultLatestVersion,
      'update_message': defaultUpdateMessage,
    });

    print('🔧 [REMOTE_CONFIG] Fetch timeout: ${fetchTimeoutSeconds}s, Min interval: ${minimumFetchIntervalMinutes}m');
    print('🔧 [REMOTE_CONFIG] Defaults - Force update: $defaultForceUpdate, Version: $defaultLatestVersion');

    // Fetch config in background without blocking app startup
    fetchConfig();

    return this;
  }

  Future<void> fetchConfig() async {
    try {
      print('🔧 [REMOTE_CONFIG] Starting fetch...');

      final activated = await _remoteConfig.fetchAndActivate();
      print('🔧 [REMOTE_CONFIG] Fetch completed. Activated: $activated');

      // Get all values
      forceUpdate.value = _remoteConfig.getBool('force_update');
      latestVersion.value = _remoteConfig.getString('latest_version');
      updateMessage.value = _remoteConfig.getString('update_message');

      // Log fetched values
      print('🔧 [REMOTE_CONFIG] ✅ Fetched values:');
      print('   - force_update: ${forceUpdate.value}');
      print('   - latest_version: ${latestVersion.value}');
      print('   - update_message: ${updateMessage.value}');

      // Get all keys to see what's available
      final allKeys = _remoteConfig.getAll();
      print('🔧 [REMOTE_CONFIG] All available keys: ${allKeys.keys.toList()}');

      // Always check version to see if update is available
      print('🔧 [REMOTE_CONFIG] Checking version...');
      await _checkVersion();
    } catch (e, stackTrace) {
      print('❌ [REMOTE_CONFIG] Error fetching remote config: $e');
      print('❌ [REMOTE_CONFIG] Stack trace: $stackTrace');
    }
  }

  Future<void> _checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      print('🔧 [REMOTE_CONFIG] Version check:');
      print('   - Current version: $currentVersion');
      print('   - Latest version: ${latestVersion.value}');

      if (_isVersionLower(currentVersion, latestVersion.value)) {
        // Update is available
        updateAvailable.value = true;
        print('🔧 [REMOTE_CONFIG] ⚠️ Update available! Current version is lower than latest.');

        // Check if it's a force update
        if (forceUpdate.value) {
          print('🔧 [REMOTE_CONFIG] 🚨 This is a FORCE UPDATE - user must update!');
        } else {
          print('🔧 [REMOTE_CONFIG] ℹ️ This is an optional update - user can skip.');
        }
      } else {
        updateAvailable.value = false;
        forceUpdate.value = false;
        print('🔧 [REMOTE_CONFIG] ✅ App is up to date.');
      }
    } catch (e, stackTrace) {
      print('❌ [REMOTE_CONFIG] Error checking version: $e');
      print('❌ [REMOTE_CONFIG] Stack trace: $stackTrace');
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

  // Get all config values for debugging
  Map<String, dynamic> getAllConfigValues() {
    return {
      'force_update': forceUpdate.value,
      'latest_version': latestVersion.value,
      'update_message': updateMessage.value,
    };
  }

  // Print current config status
  void printConfigStatus() {
    print('🔧 [REMOTE_CONFIG] Current Status:');
    print('   - Force Update: ${forceUpdate.value}');
    print('   - Latest Version: ${latestVersion.value}');
    print('   - Update Message: ${updateMessage.value}');
  }
}

