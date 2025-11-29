import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// App-wide logger utility with colorful console output
/// Supports full log output without truncation
/// Automatically disabled in release builds
class AppLogger {

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    // Disable all logs in release mode
    level: kReleaseMode ? Level.off : Level.trace,
  );

  /// Log user speech input
  static void userSaid(String text) {
    _logger.i('🎤 USER SAID (${text.length} chars):\n$text');
  }

  /// Log Polly/AI response
  static void pollySaid(String text) {
    _logger.i('🔊 POLLY SAID:\n$text');
  }

  /// Log Groq API request
  static void groqRequest({
    required String url,
    required String model,
    required List<Map<String, String>> messages,
    required double temperature,
    required int maxTokens,
    required double frequencyPenalty,
    required double presencePenalty,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('📤 GROQ REQUEST');
    buffer.writeln('URL: $url');
    buffer.writeln('Model: $model');
    buffer.writeln('Temperature: $temperature');
    buffer.writeln('Max Tokens: $maxTokens');
    buffer.writeln('Frequency Penalty: $frequencyPenalty');
    buffer.writeln('Presence Penalty: $presencePenalty');
    buffer.writeln('Messages:');
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      buffer.writeln('  [$i] ${msg['role']?.toUpperCase()}:');
      buffer.writeln('      ${msg['content']}');
    }
    _logger.d(buffer.toString());
  }

  /// Log Groq API response
  static void groqResponse({
    required int statusCode,
    required String body,
    int? durationMs,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('📥 GROQ RESPONSE');
    buffer.writeln('Status: $statusCode');
    if (durationMs != null) {
      buffer.writeln('Duration: ${durationMs}ms');
    }
    buffer.writeln('Body:');
    buffer.writeln(body);
    
    if (statusCode == 200) {
      _logger.d(buffer.toString());
    } else {
      _logger.e(buffer.toString());
    }
  }

  /// Log debug info
  static void debug(String message) {
    _logger.d(message);
  }

  /// Log info
  static void info(String message) {
    _logger.i(message);
  }

  /// Log warning
  static void warning(String message) {
    _logger.w(message);
  }

  /// Log error
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log speech recognition events
  static void speechEvent(String event, {String? details}) {
    if (details != null) {
      _logger.t('🎙️ SPEECH: $event\n$details');
    } else {
      _logger.t('🎙️ SPEECH: $event');
    }
  }
  
}

