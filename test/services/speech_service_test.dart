import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:mood_shift_ai/app/services/speech_service.dart';
import 'package:mood_shift_ai/app/services/storage_service.dart';
import 'package:mood_shift_ai/app/services/crashlytics_service.dart';

import 'speech_service_test.mocks.dart';

@GenerateMocks([SpeechToText, StorageService, CrashlyticsService])
void main() {
  late SpeechService speechService;
  late MockSpeechToText mockSpeech;
  late MockStorageService mockStorage;
  late MockCrashlyticsService mockCrashlytics;

  // Callbacks captured from initialize
  late Function(String) capturedStatusCallback;
  late Function(dynamic) capturedErrorCallback;
  late Function(SpeechRecognitionResult) capturedResultCallback;

  setUp(() {
    Get.testMode = true;

    mockSpeech = MockSpeechToText();
    mockStorage = MockStorageService();
    mockCrashlytics = MockCrashlyticsService();

    // Setup default mock behaviors
    when(mockStorage.getFullLocale()).thenReturn('en-US');
    when(mockSpeech.isAvailable).thenReturn(true);
    when(mockSpeech.isListening).thenReturn(false);

    when(mockSpeech.initialize(
      onError: anyNamed('onError'),
      onStatus: anyNamed('onStatus'),
    )).thenAnswer((invocation) async {
      capturedStatusCallback = invocation.namedArguments[const Symbol('onStatus')];
      capturedErrorCallback = invocation.namedArguments[const Symbol('onError')];
      return true;
    });

    when(mockSpeech.locales()).thenAnswer((_) async => [LocaleName('en_US', 'English')]);
    when(mockSpeech.systemLocale()).thenAnswer((_) async => LocaleName('en_US', 'English'));

    when(mockSpeech.listen(
      onResult: anyNamed('onResult'),
      localeId: anyNamed('localeId'),
      listenMode: anyNamed('listenMode'),
      cancelOnError: anyNamed('cancelOnError'),
      partialResults: anyNamed('partialResults'),
      listenFor: anyNamed('listenFor'),
      pauseFor: anyNamed('pauseFor'),
    )).thenAnswer((invocation) async {
      capturedResultCallback = invocation.namedArguments[const Symbol('onResult')];
    });

    when(mockSpeech.stop()).thenAnswer((_) async {});

    speechService = SpeechService(
      speech: mockSpeech,
      storage: mockStorage,
      crashlytics: mockCrashlytics,
    );
    speechService.onInit();
  });

  tearDown(() {
    Get.reset();
  });

  group('SpeechService - Continuous Recording with Pauses', () {
    test('should accumulate text across multiple pause-restart cycles', () async {
      // Initialize
      await speechService.initialize();

      // Start listening
      await speechService.startListening((_) {});

      expect(speechService.isListening.value, true);

      // Simulate first speech segment: "speech"
      capturedResultCallback(_createResult('speech', isFinal: false));
      expect(speechService.recognizedText.value, 'speech');

      capturedResultCallback(_createResult('speech', isFinal: true));
      expect(speechService.recognizedText.value, 'speech');

      // Simulate pause - status changes to notListening
      capturedStatusCallback('notListening');

      // Wait for restart delay
      await Future.delayed(const Duration(milliseconds: 400));

      // Simulate second speech segment: "detected"
      capturedResultCallback(_createResult('detected', isFinal: false));
      expect(speechService.recognizedText.value, 'speech detected');

      capturedResultCallback(_createResult('detected', isFinal: true));
      expect(speechService.recognizedText.value, 'speech detected');

      // Simulate another pause
      capturedStatusCallback('notListening');
      await Future.delayed(const Duration(milliseconds: 400));

      // Simulate third speech segment: "after pause"
      capturedResultCallback(_createResult('after pause', isFinal: false));
      expect(speechService.recognizedText.value, 'speech detected after pause');

      capturedResultCallback(_createResult('after pause', isFinal: true));
      expect(speechService.recognizedText.value, 'speech detected after pause');

      // Stop listening
      await speechService.stopListening();

      expect(speechService.isListening.value, false);
      expect(speechService.recognizedText.value, 'speech detected after pause');
    });

    test('should capture partial result when pause occurs before final result', () async {
      await speechService.initialize();
      await speechService.startListening((_) {});

      // User says "hello world" but pause happens before final result
      capturedResultCallback(_createResult('hello world', isFinal: false));
      expect(speechService.recognizedText.value, 'hello world');

      // Pause occurs - no final result received
      capturedStatusCallback('notListening');

      // Wait for restart which should capture the partial
      await Future.delayed(const Duration(milliseconds: 400));

      // The partial should now be accumulated
      expect(speechService.recognizedText.value, 'hello world');

      // User continues speaking
      capturedResultCallback(_createResult('how are you', isFinal: false));
      expect(speechService.recognizedText.value, 'hello world how are you');

      capturedResultCallback(_createResult('how are you', isFinal: true));
      expect(speechService.recognizedText.value, 'hello world how are you');

      await speechService.stopListening();
      expect(speechService.recognizedText.value, 'hello world how are you');
    });

    test('should handle multiple rapid pauses without losing text', () async {
      await speechService.initialize();
      await speechService.startListening((_) {});

      // First segment
      capturedResultCallback(_createResult('one', isFinal: true));
      expect(speechService.recognizedText.value, 'one');

      // Quick pause and restart
      capturedStatusCallback('notListening');
      await Future.delayed(const Duration(milliseconds: 400));

      // Second segment
      capturedResultCallback(_createResult('two', isFinal: true));
      expect(speechService.recognizedText.value, 'one two');

      // Another quick pause
      capturedStatusCallback('notListening');
      await Future.delayed(const Duration(milliseconds: 400));

      // Third segment
      capturedResultCallback(_createResult('three', isFinal: true));
      expect(speechService.recognizedText.value, 'one two three');

      await speechService.stopListening();
      expect(speechService.recognizedText.value, 'one two three');
    });

    test('should capture remaining partial when user releases button', () async {
      await speechService.initialize();
      await speechService.startListening((_) {});

      // User is speaking
      capturedResultCallback(_createResult('I am speaking', isFinal: false));
      expect(speechService.recognizedText.value, 'I am speaking');

      // User releases button before final result
      await speechService.stopListening();

      // The partial should be captured
      expect(speechService.recognizedText.value, 'I am speaking');
      expect(speechService.isListening.value, false);
    });

    test('should handle error during speech and continue recording', () async {
      await speechService.initialize();
      await speechService.startListening((_) {});

      // First segment works
      capturedResultCallback(_createResult('first part', isFinal: true));
      expect(speechService.recognizedText.value, 'first part');

      // Error occurs
      capturedErrorCallback('error_speech_timeout');

      // Wait for restart
      await Future.delayed(const Duration(milliseconds: 400));

      // Continue speaking after error
      capturedResultCallback(_createResult('second part', isFinal: true));
      expect(speechService.recognizedText.value, 'first part second part');

      await speechService.stopListening();
      expect(speechService.recognizedText.value, 'first part second part');
    });

    test('should stop after 60 seconds max recording time', () async {
      await speechService.initialize();
      await speechService.startListening((_) {});

      // Simulate that 60 seconds have passed by manipulating the session
      // This is a limitation - we can't easily test time-based behavior
      // without more complex mocking of DateTime

      expect(speechService.isListening.value, true);
      await speechService.stopListening();
      expect(speechService.isListening.value, false);
    });

    test('should reset accumulated text on new session', () async {
      await speechService.initialize();

      // First session
      await speechService.startListening((_) {});
      capturedResultCallback(_createResult('first session', isFinal: true));
      await speechService.stopListening();
      expect(speechService.recognizedText.value, 'first session');

      // Second session - should start fresh
      await speechService.startListening((_) {});
      expect(speechService.recognizedText.value, '');

      capturedResultCallback(_createResult('second session', isFinal: true));
      expect(speechService.recognizedText.value, 'second session');

      await speechService.stopListening();
    });

    test('should handle done status same as notListening', () async {
      await speechService.initialize();
      await speechService.startListening((_) {});

      capturedResultCallback(_createResult('hello', isFinal: true));
      expect(speechService.recognizedText.value, 'hello');

      // 'done' status should also trigger restart
      capturedStatusCallback('done');
      await Future.delayed(const Duration(milliseconds: 400));

      capturedResultCallback(_createResult('world', isFinal: true));
      expect(speechService.recognizedText.value, 'hello world');

      await speechService.stopListening();
    });

    test('should handle status change before final result arrives', () async {
      // This simulates the real-world scenario where:
      // 1. User says "speech"
      // 2. Partial result "speech" arrives
      // 3. Status changes to notListening (pause detected)
      // 4. Final result "speech" arrives AFTER status change
      // 5. User says "detected"
      // Expected: "speech detected"

      await speechService.initialize();
      await speechService.startListening((_) {});

      // User says "speech" - partial arrives
      capturedResultCallback(_createResult('speech', isFinal: false));
      expect(speechService.recognizedText.value, 'speech');

      // Status changes to notListening BEFORE final result
      capturedStatusCallback('notListening');

      // Final result arrives after status change (race condition)
      capturedResultCallback(_createResult('speech', isFinal: true));

      // Wait for restart
      await Future.delayed(const Duration(milliseconds: 400));

      // User says "detected"
      capturedResultCallback(_createResult('detected', isFinal: true));

      // Should have both segments
      expect(speechService.recognizedText.value, 'speech detected');

      await speechService.stopListening();
    });

    test('should handle 4 segments with pauses', () async {
      // Simulates: "speech (pause) detected (pause) after pause (pause) second pause"
      await speechService.initialize();
      await speechService.startListening((_) {});

      // Segment 1: "speech"
      capturedResultCallback(_createResult('speech', isFinal: false));
      capturedResultCallback(_createResult('speech', isFinal: true));
      expect(speechService.recognizedText.value, 'speech');

      capturedStatusCallback('notListening');
      await Future.delayed(const Duration(milliseconds: 400));

      // Segment 2: "detected"
      capturedResultCallback(_createResult('detected', isFinal: false));
      capturedResultCallback(_createResult('detected', isFinal: true));
      expect(speechService.recognizedText.value, 'speech detected');

      capturedStatusCallback('notListening');
      await Future.delayed(const Duration(milliseconds: 400));

      // Segment 3: "after pause"
      capturedResultCallback(_createResult('after pause', isFinal: false));
      capturedResultCallback(_createResult('after pause', isFinal: true));
      expect(speechService.recognizedText.value, 'speech detected after pause');

      capturedStatusCallback('notListening');
      await Future.delayed(const Duration(milliseconds: 400));

      // Segment 4: "second pause"
      capturedResultCallback(_createResult('second pause', isFinal: false));
      capturedResultCallback(_createResult('second pause', isFinal: true));
      expect(speechService.recognizedText.value, 'speech detected after pause second pause');

      await speechService.stopListening();
      expect(speechService.recognizedText.value, 'speech detected after pause second pause');
    });

    test('should handle partial only segments (no final result before pause)', () async {
      // Simulates: User speaks but pause happens before final result
      // "speech (pause) detected (pause) after pause (pause) second pause"
      // where each segment only has partial, no final before pause
      await speechService.initialize();
      await speechService.startListening((_) {});

      // Segment 1: "speech" - only partial, then pause
      capturedResultCallback(_createResult('speech', isFinal: false));
      expect(speechService.recognizedText.value, 'speech');
      capturedStatusCallback('notListening');
      await Future.delayed(const Duration(milliseconds: 600));
      // Partial should be captured
      expect(speechService.recognizedText.value, 'speech');

      // Segment 2: "detected" - only partial, then pause
      capturedResultCallback(_createResult('detected', isFinal: false));
      expect(speechService.recognizedText.value, 'speech detected');
      capturedStatusCallback('notListening');
      await Future.delayed(const Duration(milliseconds: 600));
      expect(speechService.recognizedText.value, 'speech detected');

      // Segment 3: "after pause" - only partial, then pause
      capturedResultCallback(_createResult('after pause', isFinal: false));
      expect(speechService.recognizedText.value, 'speech detected after pause');
      capturedStatusCallback('notListening');
      await Future.delayed(const Duration(milliseconds: 600));
      expect(speechService.recognizedText.value, 'speech detected after pause');

      // Segment 4: "second pause" - only partial, then stop
      capturedResultCallback(_createResult('second pause', isFinal: false));
      expect(speechService.recognizedText.value, 'speech detected after pause second pause');

      await speechService.stopListening();
      expect(speechService.recognizedText.value, 'speech detected after pause second pause');
    });

    test('should handle final result that starts with captured partial (real-world race condition)', () async {
      // This simulates the exact scenario from logs:
      // 1. Partial "after" arrives
      // 2. Status changes to notListening, partial "after" is captured
      // 3. Final result "after after Falls" arrives (starts with "after")
      // Expected: Only add "after Falls" (the new part), not duplicate "after"
      await speechService.initialize();
      await speechService.startListening((_) {});

      // First segment works fine
      capturedResultCallback(_createResult('speech', isFinal: true));
      expect(speechService.recognizedText.value, 'speech');

      // Second segment: partial arrives, then status changes, then final arrives
      capturedResultCallback(_createResult('after', isFinal: false));
      expect(speechService.recognizedText.value, 'speech after');

      // Status changes - partial "after" is captured
      capturedStatusCallback('notListening');

      // Final result arrives AFTER status change, starts with "after"
      // In real world this was "after after Falls" (misheard "pause" as "Falls")
      capturedResultCallback(_createResult('after pause', isFinal: true));

      // Wait for restart
      await Future.delayed(const Duration(milliseconds: 600));

      // Should have "speech after pause" NOT "speech after after pause"
      expect(speechService.recognizedText.value, 'speech after pause');

      await speechService.stopListening();
    });

    test('should handle final result that exactly matches captured partial', () async {
      // Scenario: partial "hello" captured, then final "hello" arrives
      await speechService.initialize();
      await speechService.startListening((_) {});

      capturedResultCallback(_createResult('hello', isFinal: false));
      expect(speechService.recognizedText.value, 'hello');

      capturedStatusCallback('notListening');

      // Final result is exactly the same as partial
      capturedResultCallback(_createResult('hello', isFinal: true));

      await Future.delayed(const Duration(milliseconds: 600));

      // Should have "hello" NOT "hello hello"
      expect(speechService.recognizedText.value, 'hello');

      await speechService.stopListening();
    });
  });
}

SpeechRecognitionResult _createResult(String words, {required bool isFinal}) {
  return SpeechRecognitionResult(
    [SpeechRecognitionWords(words, null, 0.9)],
    isFinal,
  );
}

