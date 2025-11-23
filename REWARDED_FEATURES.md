# 🎁 Rewarded Ad Features - MoodShift AI

## Overview

MoodShift AI includes two premium rewarded ad features designed to be **magical, addictive, and profitable**:

1. **⚡ 2× Stronger** - Amplify your response with 2× the energy, intensity, and hype
2. **✨ Golden Voice** - Unlock 1 hour of premium warm, empathetic voice

---

## ⚡ 2× Stronger Feature

### What It Does
- Generates a **new, amplified response** from the LLM with 2× the energy
- Speaks the response with **faster rate (1.3x), higher pitch (+20%), louder volume**
- Limited to **3 uses per session** (resets daily at midnight)

### User Flow
1. User completes a mood shift
2. Bottom sheet appears with "2× Stronger (3 left)" button
3. User taps button → watches rewarded ad
4. **Visual effects:**
   - Orange flash covers screen (300ms)
   - "⚡ 2× POWER ACTIVATED! ⚡" overlay appears (1.5s)
   - Confetti animation plays
5. LLM generates new amplified response
6. TTS speaks with 2× stronger SSML
7. Button updates to "2× Stronger (2 left)"

### Technical Implementation

#### LLM Prompt Modification
```dart
// lib/app/services/groq_llm_service.dart
Future<String> generateStrongerResponse(String originalResponse, String language) async {
  final prompt = '''You are MoodShift AI in MAXIMUM POWER MODE! 🔥⚡
  TASK: Take this response and make it 2× STRONGER – LOUDER energy, MORE intense, BIGGER hype!
  ORIGINAL RESPONSE: "$originalResponse"
  NOW MAKE IT 2× STRONGER! GO! 🚀''';
  
  // Temperature: 1.0 for more energetic responses
  // Frequency penalty: 0.3 to encourage varied vocabulary
}
```

#### TTS SSML Amplification
```dart
// lib/app/services/polly_tts_service.dart
String _buildStrongerSSML(String text) {
  return '<speak><prosody rate="130%" pitch="+20%" volume="loud">$text</prosody></speak>';
}
```

#### Session Limits
```dart
// lib/app/controllers/rewarded_controller.dart
// Resets daily at midnight
void _checkSessionReset() {
  final today = DateTime.now();
  final lastSessionDate = _storage.getLastSessionDate();
  
  if (lastSessionDate != null && !_isSameDay(DateTime.parse(lastSessionDate), today)) {
    strongerUsesRemaining.value = 3;
    _storage.setStrongerUsesRemaining(3);
  }
}
```

---

## ✨ Golden Voice Feature

### What It Does
- Unlocks **1 hour of premium warm, empathetic voice**
- Applies to **all mood shifts** during the active period
- Shows **countdown timer** in top bar
- Adds **golden glow** to mic button

### User Flow
1. User completes a mood shift
2. Bottom sheet appears with "Golden Voice" button
3. User taps button → watches rewarded ad
4. **Visual effects:**
   - Golden sparkle animation plays (2s)
   - "✨ Golden Voice Unlocked!" snackbar appears
   - Golden timer appears in top-left: "Golden: 59:59"
   - Mic button gets golden glow
5. All subsequent shifts use golden voice for 1 hour
6. Timer counts down every second
7. When expired: "✨ Golden Voice Expired" notification

### Technical Implementation

#### TTS SSML for Golden Voice
```dart
// lib/app/services/polly_tts_service.dart
String _buildGoldenSSML(String text, MoodStyle style) {
  // Slower (90%), slightly higher pitch (+10%), warm volume
  String prosody = '<prosody rate="90%" pitch="+10%" volume="medium">$text</prosody>';
  
  // Wrap in conversational speaking style
  return '<speak><amazon:domain name="conversational">$prosody</amazon:domain></speak>';
}
```

#### Timer Management
```dart
// lib/app/controllers/rewarded_controller.dart
void _startGoldenVoiceTimer() {
  _goldenVoiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    _updateGoldenVoiceStatus();
  });
}

void _updateGoldenVoiceStatus() {
  hasGoldenVoice.value = _storage.hasGoldenVoice();
  
  if (hasGoldenVoice.value) {
    final remaining = _storage.getRemainingGoldenTime();
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    goldenTimeRemaining.value = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
```

---

## 🎨 Visual Effects

### Orange Flash (2× Stronger)
```dart
// lib/app/modules/home/home_view.dart
Obx(() => rewardedController.showStrongerFlash.value
    ? Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.orange.withOpacity(0.3),
      )
    : const SizedBox.shrink())
```

### Power Overlay (2× Stronger)
```dart
Obx(() => rewardedController.showStrongerOverlay.value
    ? Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text('⚡ 2× POWER ACTIVATED! ⚡'),
        ),
      )
    : const SizedBox.shrink())
```

### Golden Sparkle Animation
```dart
Obx(() => rewardedController.showGoldenSparkle.value
    ? Center(
        child: Lottie.asset(
          'assets/animations/sparkle.json',
          repeat: false,
        ),
      )
    : const SizedBox.shrink())
```

### Golden Timer Display
```dart
Obx(() {
  final timerText = rewardedController.getGoldenTimerDisplay();
  if (timerText.isEmpty) return SizedBox.shrink();
  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
    decoration: BoxDecoration(
      color: const Color(0xFFD4AF37).withOpacity(0.15),
      borderRadius: BorderRadius.circular(20.r),
    ),
    child: Text(timerText),
  );
})
```

---

## 📊 Analytics Tracking

### Events Logged

1. **rewarded_ad_watched**
   - `ad_type`: "stronger" or "golden_voice"
   - `reward_earned`: true/false

2. **stronger_used**
   - `uses_remaining`: 0-3
   - `session_date`: ISO 8601 date string

3. **golden_voice_activated**
   - `duration_minutes`: 60
   - `activation_time`: ISO 8601 timestamp

### Implementation
```dart
// lib/app/controllers/rewarded_controller.dart
final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

void useStronger() {
  _analytics.logEvent(
    name: 'stronger_used',
    parameters: {
      'uses_remaining': strongerUsesRemaining.value,
      'session_date': _storage.getLastSessionDate(),
    },
  );
}
```

---

## 🧪 Testing

Run manual tests in `test/rewarded_features_test.dart`:

```bash
# Run all tests
flutter test test/rewarded_features_test.dart

# Or follow manual test cases in the file
```

### Key Test Cases
1. ✅ Watch ad and verify 2× stronger response
2. ✅ Use all 3 charges and verify limit
3. ✅ Verify session reset next day
4. ✅ Activate golden voice and verify timer
5. ✅ Verify golden voice TTS quality
6. ✅ Verify visual effects (flash, overlay, sparkle, glow)
7. ✅ Verify analytics events are logged
8. ✅ Verify edge cases (ad fails, API fails, caching)

---

## 🚀 How to Use (Debug Mode)

### Simulate Rewarded Ads
AdMob test ad unit IDs are already configured in `.env`:
```
ADMOB_ANDROID_REWARDED_AD_UNIT_ID=ca-app-pub-3940256099942544/5224354917
ADMOB_IOS_REWARDED_AD_UNIT_ID=ca-app-pub-3940256099942544/1712485313
```

### Test Flow
1. Run app: `flutter run`
2. Complete a mood shift (hold mic, speak, release)
3. Bottom sheet appears with superpower buttons
4. Tap "2× Stronger (3 left)" → watch test ad → verify effects
5. Tap "Golden Voice" → watch test ad → verify timer and glow

---

## 📁 Files Modified/Created

### Created
- `lib/app/controllers/rewarded_controller.dart` - Main controller for rewarded features
- `test/rewarded_features_test.dart` - Manual test cases
- `REWARDED_FEATURES.md` - This documentation

### Modified
- `lib/app/services/groq_llm_service.dart` - Added `generateStrongerResponse()`
- `lib/app/services/polly_tts_service.dart` - Added SSML builders for stronger + golden
- `lib/app/services/storage_service.dart` - Added session tracking methods
- `lib/app/services/ad_service.dart` - Added analytics tracking
- `lib/app/modules/home/home_controller.dart` - Integrated rewarded controller
- `lib/app/modules/home/home_view.dart` - Added visual effects
- `lib/app/modules/home/home_binding.dart` - Added rewarded controller binding
- `pubspec.yaml` - Added `firebase_analytics: ^10.8.0`

---

## 🎯 Success Metrics

### User Engagement
- **2× Stronger usage rate**: % of shifts that use 2× stronger
- **Golden Voice activation rate**: % of users who activate golden voice
- **Repeat usage**: Users who use features multiple times

### Monetization
- **Rewarded ad views**: Total ads watched for both features
- **eCPM**: Effective cost per mille (revenue per 1000 impressions)
- **Revenue per user**: Average revenue from rewarded ads

### Retention
- **Daily return rate**: Users who come back to use features again
- **Session length**: Time spent in app when using features

---

## 🔮 Future Enhancements

1. **3× MEGA MODE** - Even more intense (5 uses/week, premium tier)
2. **Voice Packs** - Different voice styles (energetic, calm, motivational)
3. **Custom Timers** - 30min, 2hr, 24hr golden voice options
4. **Combo Rewards** - Use both features together for special effects
5. **Streak Bonuses** - Extra uses for maintaining daily streaks

---

## 💡 Tips for Maximum Addictiveness

1. **Visual Feedback**: Orange flash + power overlay make users FEEL the power
2. **Instant Gratification**: Effects trigger immediately after ad
3. **Scarcity**: 3 uses/day creates urgency and value
4. **Progress Tracking**: Timer and uses remaining create engagement
5. **Quality Difference**: Golden voice is noticeably better → users want it
6. **Celebration**: Confetti + sparkles make it feel like a reward

---

## 🐛 Troubleshooting

### Ads not showing?
- Check internet connection
- Verify AdMob test IDs in `.env`
- Check console for ad load errors

### 2× Stronger not amplifying?
- Check Groq API key in `.env`
- Verify LLM service is initialized
- Check console for API errors

### Golden voice sounds normal?
- Verify Polly credentials in `.env`
- Check if golden voice is actually active (timer visible?)
- Verify SSML is being applied (check logs)

### Timer not counting down?
- Check if timer is started in `onInit()`
- Verify storage methods are working
- Check console for timer errors

---

Made with ❤️ for MoodShift AI users

