import 'dart:ui';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';
import 'package:mood_shift_ai/app/utils/app_logger.dart';
import 'storage_service.dart';

/// Firebase Analytics Service for MoodShift AI
/// Handles all analytics events, user properties, and session tracking.
/// 
/// 2025 Best Practices:
/// - Uses FirebaseAnalyticsObserver for automatic screen tracking
/// - Logs DAU events (first_open, session_start, app_open are automatic)
/// - Tracks session count per user
/// - Sets user properties for segmentation
/// - Logs custom events for ads, AI usage, and TTS
/// - No PII collected - fully anonymous
class AnalyticsService extends GetxService {
  static AnalyticsService get to => Get.find<AnalyticsService>();
  
  late final FirebaseAnalytics _analytics;
  late final FirebaseAnalyticsObserver _observer;
  late final StorageService _storage;
  
  // Storage keys for analytics
  static const String _keyTotalSessions = 'analytics_total_sessions';
  static const String _keyHasUsedStronger = 'analytics_has_used_stronger';
  static const String _keyHasUsedCrystal = 'analytics_has_used_crystal';
  static const String _keyUserCountry = 'analytics_user_country';
  
  /// Get the analytics observer for navigation tracking
  FirebaseAnalyticsObserver get observer => _observer;
  
  Future<AnalyticsService> init() async {
    _analytics = FirebaseAnalytics.instance;
    _observer = FirebaseAnalyticsObserver(analytics: _analytics);
    _storage = Get.find<StorageService>();
    
    // Initialize session and user properties
    await _initializeSession();
    await _setUserProperties();
    
    AppLogger.info('📊 AnalyticsService initialized');
    return this;
  }
  
  /// Initialize session tracking on app start
  Future<void> _initializeSession() async {
    // Increment session count
    final currentSessions = _storage.box.read<int>(_keyTotalSessions) ?? 0;
    final newSessionCount = currentSessions + 1;
    await _storage.box.write(_keyTotalSessions, newSessionCount);
    
    // Set user country from device locale
    final locale = PlatformDispatcher.instance.locale;
    final countryCode = locale.countryCode ?? 'US';
    await _storage.box.write(_keyUserCountry, countryCode);
    
    AppLogger.debug('📊 Session #$newSessionCount started | Country: $countryCode');
  }
  
  /// Set user properties for segmentation
  Future<void> _setUserProperties() async {
    final totalSessions = _storage.box.read<int>(_keyTotalSessions) ?? 1;
    final hasUsedStronger = _storage.box.read<bool>(_keyHasUsedStronger) ?? false;
    final hasUsedCrystal = _storage.box.read<bool>(_keyHasUsedCrystal) ?? false;
    final userCountry = _storage.box.read<String>(_keyUserCountry) ?? 'US';
    
    // Set all user properties
    await _analytics.setUserProperty(name: 'user_country', value: userCountry);
    await _analytics.setUserProperty(name: 'total_sessions', value: totalSessions.toString());
    await _analytics.setUserProperty(name: 'has_used_stronger', value: hasUsedStronger.toString());
    await _analytics.setUserProperty(name: 'has_used_crystal', value: hasUsedCrystal.toString());
    
    AppLogger.debug('📊 User properties set: country=$userCountry, sessions=$totalSessions, stronger=$hasUsedStronger, crystal=$hasUsedCrystal');
  }
  
  // ========== AI USAGE EVENTS ==========

  /// Mark that user has used stronger mode (for user property tracking)
  Future<void> markStrongerModeUsed() async {
    await _storage.box.write(_keyHasUsedStronger, true);
    await _analytics.setUserProperty(name: 'has_used_stronger', value: 'true');
    AppLogger.debug('📊 User property updated: has_used_stronger=true');
  }

  /// Mark that user has used crystal voice (for user property tracking)
  Future<void> markCrystalVoiceUsed() async {
    await _storage.box.write(_keyHasUsedCrystal, true);
    await _analytics.setUserProperty(name: 'has_used_crystal', value: 'true');
    AppLogger.debug('📊 User property updated: has_used_crystal=true');
  }
  
  /// Log Groq tokens used event
  /// [mode] can be: "normal", "stronger", "crystal"
  Future<void> logGrokTokensUsed({
    required String mode,
    required int inputTokens,
    required int outputTokens,
    required int totalTokens,
  }) async {
    await _analytics.logEvent(
      name: 'grok_tokens_used',
      parameters: {
        'mode': mode,
        'input_tokens': inputTokens,
        'output_tokens': outputTokens,
        'total_tokens': totalTokens,
      },
    );
    AppLogger.debug('📊 Event: grok_tokens_used | mode=$mode, total=$totalTokens');
  }
  
  /// Log Polly TTS used event
  /// [mode] can be: "normal", "stronger", "crystal"
  /// [voiceEngine] can be: "standard", "neural", "generative"
  /// [characterCount] is the number of characters sent to Polly for synthesis
  Future<void> logPollyTtsUsed({
    required String mode,
    required String voiceEngine,
    required int characterCount,
  }) async {
    await _analytics.logEvent(
      name: 'polly_tts_used',
      parameters: {
        'mode': mode,
        'voice_engine': voiceEngine,
        'character_count': characterCount,
      },
    );
    AppLogger.debug('📊 Event: polly_tts_used | mode=$mode, engine=$voiceEngine, chars=$characterCount');
  }
}

