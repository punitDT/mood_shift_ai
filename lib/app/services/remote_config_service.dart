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

    fetchConfig();

    return this;
  }

  Future<void> fetchConfig() async {
    try {
      await _remoteConfig.fetchAndActivate();

      forceUpdate.value = _remoteConfig.getBool('force_update');
      latestVersion.value = _remoteConfig.getString('latest_version');
      updateMessage.value = _remoteConfig.getString('update_message');

      await _checkVersion();
    } catch (e) {
      // Silently fail - not critical
    }
  }

  Future<void> _checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isVersionLower(currentVersion, latestVersion.value)) {
        updateAvailable.value = true;
      } else {
        updateAvailable.value = false;
        forceUpdate.value = false;
      }
    } catch (e) {
      // Silently fail - not critical
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

  Map<String, dynamic> getAllConfigValues() {
    return {
      'force_update': forceUpdate.value,
      'latest_version': latestVersion.value,
      'update_message': updateMessage.value,
    };
  }
}
