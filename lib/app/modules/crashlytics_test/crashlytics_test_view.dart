import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../services/crashlytics_service.dart';

/// Test screen for triggering all types of Crashlytics errors
/// This screen should be removed before production release
class CrashlyticsTestView extends StatelessWidget {
  const CrashlyticsTestView({super.key});

  @override
  Widget build(BuildContext context) {
    final crashlytics = Get.find<CrashlyticsService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0a0520),
      appBar: AppBar(
        backgroundColor: const Color(0xFF150a2e),
        title: Text(
          '🔥 Crashlytics Test',
          style: TextStyle(fontSize: 18.sp, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWarningBanner(),
            SizedBox(height: 20.h),
            _buildSection('Ad Errors', [
              _TestButton(
                title: 'Interstitial Show Failed',
                subtitle: 'Ad Error: show_interstitial',
                color: Colors.orange,
                onTap: () => crashlytics.reportAdError(
                  Exception('Test: Interstitial ad failed to show'),
                  StackTrace.current,
                  operation: 'show_interstitial',
                  adType: 'interstitial',
                  errorCode: 3,
                  errorMessage: 'No fill - no ads available',
                ),
              ),
              _TestButton(
                title: 'Rewarded (Stronger) Show Failed',
                subtitle: 'Ad Error: show_rewarded_stronger',
                color: Colors.orange,
                onTap: () => crashlytics.reportAdError(
                  Exception('Test: Rewarded ad (Stronger) failed to show'),
                  StackTrace.current,
                  operation: 'show_rewarded_stronger',
                  adType: 'rewarded',
                  errorCode: 2,
                  errorMessage: 'Network error',
                ),
              ),
              _TestButton(
                title: 'Rewarded (Crystal) Show Failed',
                subtitle: 'Ad Error: show_rewarded_crystal',
                color: Colors.orange,
                onTap: () => crashlytics.reportAdError(
                  Exception('Test: Rewarded ad (Crystal) failed to show'),
                  StackTrace.current,
                  operation: 'show_rewarded_crystal',
                  adType: 'rewarded',
                  errorCode: 1,
                  errorMessage: 'Ad not ready',
                ),
              ),
              _TestButton(
                title: 'Rewarded (RemoveAds) Show Failed',
                subtitle: 'Ad Error: show_rewarded_remove_ads',
                color: Colors.orange,
                onTap: () => crashlytics.reportAdError(
                  Exception('Test: Rewarded ad (RemoveAds) failed to show'),
                  StackTrace.current,
                  operation: 'show_rewarded_remove_ads',
                  adType: 'rewarded',
                  errorCode: 0,
                  errorMessage: 'Internal error',
                ),
              ),
            ]),
            SizedBox(height: 16.h),
            _buildSection('LLM Errors', [
              _TestButton(
                title: 'Generate Response Timeout',
                subtitle: 'LLM API Error: generateResponse',
                color: Colors.blue,
                onTap: () => crashlytics.reportLLMError(
                  Exception('Test: LLM request timed out after 30 seconds'),
                  StackTrace.current,
                  operation: 'generateResponse',
                  model: 'llama-3.3-70b-versatile',
                  userInput: 'I feel stressed today',
                ),
              ),
              _TestButton(
                title: 'Generate Response API Error',
                subtitle: 'LLM API Error: generateResponse (500)',
                color: Colors.blue,
                onTap: () => crashlytics.reportLLMError(
                  Exception('Test: Groq API returned 500 Internal Server Error'),
                  StackTrace.current,
                  operation: 'generateResponse',
                  model: 'llama-3.3-70b-versatile',
                  statusCode: 500,
                ),
              ),
              _TestButton(
                title: 'Stronger Response Failed',
                subtitle: 'LLM API Error: generateStrongerResponse',
                color: Colors.blue,
                onTap: () => crashlytics.reportLLMError(
                  Exception('Test: Failed to generate stronger response'),
                  StackTrace.current,
                  operation: 'generateStrongerResponse',
                  model: 'llama-3.3-70b-versatile',
                  statusCode: 429,
                ),
              ),
            ]),
            SizedBox(height: 16.h),
            _buildSection('TTS Errors', [
              _TestButton(
                title: 'Polly Speak Failed',
                subtitle: 'TTS Error: speak',
                color: Colors.purple,
                onTap: () => crashlytics.reportTTSError(
                  Exception('Test: AWS Polly synthesis failed'),
                  StackTrace.current,
                  operation: 'speak',
                  engine: 'generative',
                  voiceId: 'Matthew',
                  locale: 'en-US',
                  textLength: 150,
                ),
              ),
              _TestButton(
                title: 'Polly Stronger Speak Failed',
                subtitle: 'TTS Error: speakStronger',
                color: Colors.purple,
                onTap: () => crashlytics.reportTTSError(
                  Exception('Test: AWS Polly stronger synthesis failed'),
                  StackTrace.current,
                  operation: 'speakStronger',
                  engine: 'neural',
                  voiceId: 'Joanna',
                  locale: 'en-US',
                  textLength: 200,
                ),
              ),
              _TestButton(
                title: 'Polly Synthesis Failed',
                subtitle: 'TTS Error: _synthesizeWithPolly',
                color: Colors.purple,
                onTap: () => crashlytics.reportTTSError(
                  Exception('Test: Polly API returned status 503'),
                  StackTrace.current,
                  operation: '_synthesizeWithPolly',
                  engine: 'neural',
                  voiceId: 'Matthew',
                  locale: 'en-US',
                ),
              ),
              _TestButton(
                title: 'Audio Playback Failed',
                subtitle: 'TTS Error: _playAudioFile',
                color: Colors.purple,
                onTap: () => crashlytics.reportTTSError(
                  Exception('Test: Failed to play audio file'),
                  StackTrace.current,
                  operation: '_playAudioFile',
                ),
              ),
            ]),
            SizedBox(height: 16.h),
            _buildSection('Speech Recognition Errors', [
              _TestButton(
                title: 'Speech Init Failed',
                subtitle: 'Speech Recognition Error: initialize',
                color: Colors.green,
                onTap: () => crashlytics.reportSpeechError(
                  Exception('Test: Speech recognition initialization failed'),
                  StackTrace.current,
                  operation: 'initialize',
                  isAvailable: false,
                ),
              ),
              _TestButton(
                title: 'Speech Listen Failed',
                subtitle: 'Speech Recognition Error: listen',
                color: Colors.green,
                onTap: () => crashlytics.reportSpeechError(
                  Exception('Test: Speech recognition listen failed'),
                  StackTrace.current,
                  operation: 'listen',
                  locale: 'en-US',
                  isAvailable: true,
                ),
              ),
            ]),
            SizedBox(height: 16.h),
            _buildSection('User Flow Errors', [
              _TestButton(
                title: 'Mood Shift Flow Failed',
                subtitle: 'User Flow Error: mood_shift',
                color: Colors.red,
                onTap: () => crashlytics.reportUserFlowError(
                  Exception('Test: Mood shift flow failed at process_input'),
                  StackTrace.current,
                  flow: 'mood_shift',
                  step: 'process_input',
                  context: {'current_state': 'listening', 'language': 'en'},
                ),
              ),
              _TestButton(
                title: 'Service Init Failed',
                subtitle: 'Generic Error: service_initialization',
                color: Colors.red,
                onTap: () => crashlytics.reportError(
                  Exception('Test: HomeController service initialization failed'),
                  StackTrace.current,
                  reason: 'HomeController service initialization failed',
                  customKeys: {
                    'error_type': 'service_initialization',
                    'controller': 'HomeController',
                  },
                ),
              ),
            ]),
            SizedBox(height: 16.h),
            _buildSection('Storage Errors', [
              _TestButton(
                title: 'Storage Read Failed',
                subtitle: 'Storage Error: read',
                color: Colors.teal,
                onTap: () => crashlytics.reportStorageError(
                  Exception('Test: Failed to read from storage'),
                  StackTrace.current,
                  operation: 'read',
                  key: 'user_preferences',
                ),
              ),
              _TestButton(
                title: 'Storage Write Failed',
                subtitle: 'Storage Error: write',
                color: Colors.teal,
                onTap: () => crashlytics.reportStorageError(
                  Exception('Test: Failed to write to storage'),
                  StackTrace.current,
                  operation: 'write',
                  key: 'session_data',
                ),
              ),
            ]),
            SizedBox(height: 16.h),
            _buildSection('Network Errors', [
              _TestButton(
                title: 'Groq API Network Error',
                subtitle: 'Network Error: groq_api',
                color: Colors.amber,
                onTap: () => crashlytics.reportNetworkError(
                  Exception('Test: Network request to Groq API failed'),
                  StackTrace.current,
                  service: 'groq_api',
                  endpoint: '/chat/completions',
                  statusCode: 503,
                  method: 'POST',
                ),
              ),
              _TestButton(
                title: 'AWS Polly Network Error',
                subtitle: 'Network Error: aws_polly',
                color: Colors.amber,
                onTap: () => crashlytics.reportNetworkError(
                  Exception('Test: Network request to AWS Polly failed'),
                  StackTrace.current,
                  service: 'aws_polly',
                  endpoint: '/synthesize-speech',
                  statusCode: 504,
                  method: 'POST',
                ),
              ),
            ]),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'These buttons send test errors to Firebase Crashlytics. Only works in RELEASE mode. Remove this screen before production!',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.red.shade200,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.h),
        ...children,
      ],
    );
  }
}

class _TestButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _TestButton({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: () {
            onTap();
            Get.rawSnackbar(
              message: 'Error sent to Crashlytics (release mode only)',
              backgroundColor: color.withOpacity(0.9),
              duration: const Duration(seconds: 2),
              margin: EdgeInsets.all(16.w),
              borderRadius: 12.r,
            );
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.bug_report, color: color, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.send, color: color, size: 18.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

