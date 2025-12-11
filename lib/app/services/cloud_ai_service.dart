import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'device_service.dart';
import 'storage_service.dart';
import 'crashlytics_service.dart';
import 'analytics_service.dart';
import '../utils/app_logger.dart';

/// Token usage from Groq API
class TokenUsage {
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;

  TokenUsage({
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
  });

  factory TokenUsage.fromJson(Map<String, dynamic> json) {
    return TokenUsage(
      inputTokens: json['inputTokens'] ?? 0,
      outputTokens: json['outputTokens'] ?? 0,
      totalTokens: json['totalTokens'] ?? 0,
    );
  }
}

/// Response from Cloud Function
class CloudAIResponse {
  final bool success;
  final String response;
  final String audioBase64;
  final String voiceId;
  final String engine;
  final TokenUsage? tokenUsage;
  final String? error;

  CloudAIResponse({
    required this.success,
    required this.response,
    required this.audioBase64,
    required this.voiceId,
    required this.engine,
    this.tokenUsage,
    this.error,
  });

  factory CloudAIResponse.fromJson(Map<String, dynamic> json) {
    return CloudAIResponse(
      success: json['success'] ?? false,
      response: json['response'] ?? '',
      audioBase64: json['audioBase64'] ?? '',
      voiceId: json['voiceId'] ?? '',
      engine: json['engine'] ?? '',
      tokenUsage: json['tokenUsage'] != null
          ? TokenUsage.fromJson(json['tokenUsage'])
          : null,
      error: json['error'],
    );
  }

  factory CloudAIResponse.error(String message) {
    return CloudAIResponse(
      success: false,
      response: '',
      audioBase64: '',
      voiceId: '',
      engine: '',
      error: message,
    );
  }
}

/// Service to call Cloud Functions for AI processing
class CloudAIService extends GetxService {
  late final DeviceService _deviceService;
  late final StorageService _storage;
  late final CrashlyticsService _crashlytics;
  AnalyticsService? _analytics;
  late final String _cloudFunctionUrl;
  late final int _timeoutSeconds;

  @override
  void onInit() {
    super.onInit();
    _deviceService = Get.find<DeviceService>();
    _storage = Get.find<StorageService>();
    _crashlytics = Get.find<CrashlyticsService>();

    // Get analytics service (may not be available during early init)
    try {
      _analytics = Get.find<AnalyticsService>();
    } catch (_) {
      // AnalyticsService not available yet - will be set later
    }

    // Use dev or prod URL based on DEBUG_MODE
    final isDebugMode = dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
    if (isDebugMode) {
      _cloudFunctionUrl = dotenv.env['CLOUD_FUNCTION_URL_DEV'] ??
          'https://us-central1-mood-shift-ai-dev.cloudfunctions.net/processUserInput';
    } else {
      _cloudFunctionUrl = dotenv.env['CLOUD_FUNCTION_URL_PROD'] ??
          'https://us-central1-mood-shift-ai.cloudfunctions.net/processUserInput';
    }
    _timeoutSeconds = int.tryParse(dotenv.env['CLOUD_FUNCTION_TIMEOUT'] ?? '30') ?? 30;

    AppLogger.info('☁️ Cloud Function URL: $_cloudFunctionUrl (DEBUG_MODE: $isDebugMode)');
  }

  /// Process user input through Cloud Function
  /// Returns response text and audio URL
  Future<CloudAIResponse> processUserInput(String text) async {
    return _callCloudFunction(
      text: text,
      strongerMode: false,
    );
  }

  /// Generate 2× stronger response through Cloud Function
  Future<CloudAIResponse> processStronger(String originalResponse) async {
    return _callCloudFunction(
      text: '',
      strongerMode: true,
      originalResponse: originalResponse,
    );
  }

  Future<CloudAIResponse> _callCloudFunction({
    required String text,
    required bool strongerMode,
    String? originalResponse,
  }) async {
    try {
      final deviceId = _deviceService.deviceId;
      final language = _storage.getLanguageCode();
      final locale = _storage.getFullLocale();
      final voiceGender = _storage.getVoiceGender();
      final crystalVoice = _storage.hasCrystalVoice();

      final requestBody = {
        'deviceId': deviceId,
        'text': text,
        'language': language,
        'locale': locale,
        'voiceGender': voiceGender,
        'crystalVoice': crystalVoice,
        'strongerMode': strongerMode,
        if (originalResponse != null) 'originalResponse': originalResponse,
      };

      AppLogger.info('🌐 CLOUD FUNCTION REQUEST: $requestBody');

      // Get App Check token for request authentication
      String? appCheckToken;
      try {
        appCheckToken = await FirebaseAppCheck.instance.getToken();
        AppLogger.info('🔐 App Check token obtained: ${appCheckToken != null ? "yes (${appCheckToken.length} chars)" : "null"}');
      } catch (e, stackTrace) {
        AppLogger.warning('🔐 Failed to get App Check token: $e');
        // Report to Crashlytics for debugging
        _crashlytics.reportError(
          e,
          stackTrace,
          reason: 'Failed to get App Check token',
          customKeys: {'cloud_function_url': _cloudFunctionUrl},
        );
        // Continue without token - Cloud Function will reject in release mode
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (appCheckToken != null) 'X-Firebase-AppCheck': appCheckToken,
      };

      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(
        Duration(seconds: _timeoutSeconds),
        onTimeout: () {
          throw Exception('Cloud Function timeout after $_timeoutSeconds seconds');
        },
      );

      AppLogger.info('🌐 CLOUD FUNCTION RESPONSE: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cloudResponse = CloudAIResponse.fromJson(data);

        // Log analytics events for successful responses (non-blocking)
        _logAnalyticsEvents(
          cloudResponse: cloudResponse,
          strongerMode: strongerMode,
          crystalVoice: crystalVoice,
        );

        return cloudResponse;
      } else {
        final errorMsg = 'Cloud Function error: ${response.statusCode}';
        _crashlytics.reportError(
          Exception(errorMsg),
          StackTrace.current,
          reason: 'Cloud Function HTTP error',
          customKeys: {'statusCode': response.statusCode, 'body': response.body},
        );
        return CloudAIResponse.error(errorMsg);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Cloud Function error', e, stackTrace);
      _crashlytics.reportError(e, stackTrace, reason: 'Cloud Function call failed');
      return CloudAIResponse.error(e.toString());
    }
  }

  /// Log analytics events for AI usage (non-blocking, fire-and-forget)
  /// Uses actual token counts from Groq API response
  void _logAnalyticsEvents({
    required CloudAIResponse cloudResponse,
    required bool strongerMode,
    required bool crystalVoice,
  }) {
    // Ensure analytics service is available
    if (_analytics == null) {
      try {
        _analytics = Get.find<AnalyticsService>();
      } catch (_) {
        return; // Analytics not available
      }
    }

    // Determine mode for analytics
    final String mode;
    if (strongerMode) {
      mode = 'stronger';
    } else if (crystalVoice) {
      mode = 'crystal';
    } else {
      mode = 'normal';
    }

    // Log Groq tokens used event with actual token counts from API
    final tokenUsage = cloudResponse.tokenUsage;
    if (tokenUsage != null) {
      _analytics?.logGrokTokensUsed(
        mode: mode,
        inputTokens: tokenUsage.inputTokens,
        outputTokens: tokenUsage.outputTokens,
        totalTokens: tokenUsage.totalTokens,
      );
    }

    // Log Polly TTS used event with character count
    _analytics?.logPollyTtsUsed(
      feature: mode,
      voiceEngine: cloudResponse.engine.toLowerCase(),
      characterCount: cloudResponse.response.length,
    );

    // Update user properties for feature usage
    if (strongerMode) {
      _analytics?.markStrongerModeUsed();
    } else if (crystalVoice) {
      _analytics?.markCrystalVoiceUsed();
    }
  }
}

