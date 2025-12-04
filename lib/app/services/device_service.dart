import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'storage_service.dart';

/// Service to manage device identification for Cloud Functions
/// Generates and persists a unique device ID using UUID v4
class DeviceService extends GetxService {
  static const String _deviceIdKey = 'device_id';
  
  late final StorageService _storage;
  String? _deviceId;

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();
    _initializeDeviceId();
  }

  void _initializeDeviceId() {
    // Try to get existing device ID from storage
    _deviceId = _storage.box.read(_deviceIdKey);
    
    // If no device ID exists, generate a new one
    if (_deviceId == null || _deviceId!.isEmpty) {
      _deviceId = const Uuid().v4();
      _storage.box.write(_deviceIdKey, _deviceId);
    }
  }

  /// Get the unique device ID
  /// This ID is used to identify the device for conversation history
  String get deviceId {
    if (_deviceId == null) {
      _initializeDeviceId();
    }
    return _deviceId!;
  }

  /// Reset the device ID (useful for testing or privacy reset)
  void resetDeviceId() {
    _deviceId = const Uuid().v4();
    _storage.box.write(_deviceIdKey, _deviceId);
  }
}

