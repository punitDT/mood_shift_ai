# 🔧 Debug Reference Card
## Quick Debug Guide for MoodShift AI Features

---

## 🎯 FEATURE 1: Interstitial Ad Counter

### Debug Logs to Watch

```
🎯 [AD DEBUG] Shift counter: X
⏭️  [AD DEBUG] Skipping interstitial (counter: X, loaded: true/false)
✅ [AD DEBUG] Showing interstitial ad on shift #X
```

### Expected Behavior by Shift Number

| Shift # | Counter | Show Ad? | Counter After |
|---------|---------|----------|---------------|
| 1       | 1       | ❌ No    | 1             |
| 2       | 2       | ❌ No    | 2             |
| 3       | 3       | ❌ No    | 3             |
| **4**   | **4**   | **✅ YES** | **0** (reset) |
| 5       | 1       | ❌ No    | 1             |
| 6       | 2       | ❌ No    | 2             |
| 7       | 3       | ❌ No    | 3             |
| **8**   | **4**   | **✅ YES** | **0** (reset) |
| 9       | 1       | ❌ No    | 1             |

### Key Code Locations

**Counter Increment:**
```dart
// lib/app/modules/home/home_controller.dart:152
_storage.incrementShiftCounter();
```

**Ad Show Logic:**
```dart
// lib/app/services/ad_service.dart:121-126
final counter = _storage.getShiftCounter();
if (counter == 4 && isInterstitialLoaded.value && interstitialAd != null) {
  interstitialAd?.show();
  _storage.resetShiftCounter();
}
```

**Storage Methods:**
```dart
// lib/app/services/storage_service.dart
int getShiftCounter()           // Get current counter
void incrementShiftCounter()    // Increment by 1
void resetShiftCounter()        // Reset to 0
```

### Common Issues & Fixes

**Issue: Ad shows on every shift after 4th**
- ❌ Wrong: `counter >= 4`
- ✅ Correct: `counter == 4`
- Location: `lib/app/services/ad_service.dart:123`

**Issue: Counter doesn't persist**
- Check: GetStorage initialized in main.dart
- Check: `shift_counter` key in storage
- Debug: Print `_storage.getShiftCounter()` on app start

**Issue: Ad doesn't show on 4th shift**
- Check: `isInterstitialLoaded.value` is true
- Check: `interstitialAd` is not null
- Check: `_storage.isAdFree()` returns false
- Debug: Add print before `if (counter == 4...)`

---

## ✨ FEATURE 2: Golden Voice Timer

### Debug Logs to Watch

```
✨ [GOLDEN DEBUG] Golden Voice activated until: 2025-11-22 15:30:00.000
⏱️  [GOLDEN DEBUG] Time remaining: 59:45
⏱️  [GOLDEN DEBUG] Time remaining: 59:44
🔄 [GOLDEN DEBUG] Golden Voice cleared
```

### Expected UI States

| State | Mic Color | Glow | Timer | Button Text | Button Enabled |
|-------|-----------|------|-------|-------------|----------------|
| Inactive | Purple | Normal | Hidden | "Unlock Golden Voice 1 hour" | ✅ Yes |
| Active (59:45) | Gold | Golden | "Golden: 59:45" | "Golden Active – 59:45" | ❌ No |
| Active (30:00) | Gold | Golden | "Golden: 30:00" | "Golden Active – 30:00" | ❌ No |
| Expired | Purple | Normal | Hidden | "Unlock Golden Voice 1 hour" | ✅ Yes |

### Key Code Locations

**Timer Update (Every Second):**
```dart
// lib/app/modules/home/home_controller.dart:65-77
_goldenVoiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
  _updateGoldenVoiceStatus();
});
```

**Golden Voice Check:**
```dart
// lib/app/services/storage_service.dart:115-127
bool hasGoldenVoice() {
  final goldenUntil = _box.read('golden_voice_until');
  if (goldenUntil == null) return false;
  
  final until = DateTime.parse(goldenUntil);
  final hasGolden = DateTime.now().isBefore(until);
  
  if (!hasGolden) {
    _box.remove('golden_voice_until');
  }
  
  return hasGolden;
}
```

**Remaining Time Calculation:**
```dart
// lib/app/services/storage_service.dart:135-143
Duration getRemainingGoldenTime() {
  final goldenUntil = _box.read('golden_voice_until');
  if (goldenUntil == null) return Duration.zero;
  
  final until = DateTime.parse(goldenUntil);
  final remaining = until.difference(DateTime.now());
  
  return remaining.isNegative ? Duration.zero : remaining;
}
```

**Voice Modulation:**
```dart
// lib/app/services/tts_service.dart:118-126
if (_storage.hasGoldenVoice()) {
  await _tts.setSpeechRate(rate * 0.9);  // 10% slower
  await _tts.setPitch(pitch * 1.1);      // 10% higher/warmer
} else {
  await _tts.setSpeechRate(rate);
  await _tts.setPitch(pitch);
}
```

### Common Issues & Fixes

**Issue: Timer not visible**
- Check: `hasGoldenVoice.value` is true
- Check: `goldenTimeRemaining.value` is not empty
- Debug: Print both values in `_updateGoldenVoiceStatus()`
- Location: `lib/app/modules/home/home_view.dart:177-198`

**Issue: Timer doesn't count down**
- Check: `_goldenVoiceTimer` is created in `onInit()`
- Check: Timer not cancelled prematurely
- Debug: Add print in timer callback
- Location: `lib/app/modules/home/home_controller.dart:65`

**Issue: Timer doesn't persist**
- Check: `golden_voice_until` stored as ISO string
- Check: GetStorage initialized
- Debug: Print `_storage.getGoldenVoiceEndTime()` after restart
- Location: `lib/app/services/storage_service.dart:129`

**Issue: Golden glow not showing**
- Check: `controller.hasGoldenVoice.value` is true
- Check: Gradient colors are gold/orange
- Check: BoxShadow has amber color
- Location: `lib/app/modules/home/home_view.dart:217-237`

**Issue: Voice doesn't sound different**
- Check: `_storage.hasGoldenVoice()` returns true
- Check: TTS rate and pitch are modified
- Debug: Print rate/pitch values before speaking
- Location: `lib/app/services/tts_service.dart:118-126`

---

## 🔍 Quick Debug Commands

### View Logs (Android)
```bash
# All logs
adb logcat | grep -E "\[AD DEBUG\]|\[GOLDEN DEBUG\]"

# Just ad counter
adb logcat | grep "AD DEBUG"

# Just golden voice
adb logcat | grep "GOLDEN DEBUG"
```

### View Logs (iOS)
```bash
# In Xcode Console, filter by:
[AD DEBUG]
[GOLDEN DEBUG]
```

### Check Storage Values
```dart
// Add to home_controller.dart onInit() for debugging:
print('🔍 DEBUG: Shift counter = ${_storage.getShiftCounter()}');
print('🔍 DEBUG: Has golden = ${_storage.hasGoldenVoice()}');
print('🔍 DEBUG: Golden remaining = ${_storage.getRemainingGoldenTime()}');
```

### Reset Everything
```dart
// Add temporary button in UI for testing:
void resetEverything() {
  _storage.resetShiftCounter();
  _storage.clearGoldenVoice();
  print('🔄 All data reset');
}
```

---

## 📱 Testing Shortcuts

### Quick Test: Interstitial
```
1. Clear app data
2. Complete 4 shifts (say short phrases)
3. Verify ad shows on 4th only
4. Check logs for counter values
```

### Quick Test: Golden Voice
```
1. Complete 1 shift
2. Tap "Unlock Golden Voice"
3. Watch ad
4. Verify: gold mic + timer + disabled button
5. Wait 10s, verify timer counts down
6. Close/reopen app, verify persists
```

### Quick Test: Both Together
```
1. Clear app data
2. Complete 3 shifts (no ad)
3. Complete 4th shift (ad shows)
4. Unlock golden voice
5. Verify: counter reset + golden active
6. Complete 4 more shifts
7. Verify: ad shows on 8th shift
8. Verify: golden still active during shifts
```

---

## 🎨 UI Element Identifiers

### Golden Voice Active
```dart
// Mic gradient colors
colors: [Color(0xFFFFD700), Color(0xFFFFA500)]  // Gold to Orange

// Glow shadow
color: Colors.amber.withOpacity(0.7)
blurRadius: 40
spreadRadius: 15

// Timer badge
gradient: LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)])
text: "Golden: MM:SS"
```

### Golden Voice Inactive
```dart
// Mic gradient colors
colors: [Colors.purple, Colors.deepPurple]

// Glow shadow
color: Colors.purple.withOpacity(0.5)
blurRadius: 20
spreadRadius: 5

// No timer badge
```

---

## 🧪 Test Data

### Sample Phrases for Quick Testing
```
Shift 1: "I feel stressed"
Shift 2: "I'm feeling better"
Shift 3: "Tell me something positive"
Shift 4: "I need motivation"
Shift 5: "Help me relax"
Shift 6: "I'm anxious"
Shift 7: "Give me energy"
Shift 8: "I'm tired"
```

### Expected Timer Values
```
After activation: 59:59 - 60:00
After 1 minute:   58:59 - 59:00
After 30 minutes: 29:59 - 30:00
After 59 minutes: 00:59 - 01:00
After 60 minutes: 00:00 (expired)
```

---

## ✅ Verification Checklist

### Before Testing
- [ ] Code changes applied
- [ ] App built in release mode
- [ ] Device has internet connection
- [ ] Logs visible in console

### During Testing
- [ ] Debug logs appear
- [ ] Counter values correct
- [ ] Timer counts down
- [ ] UI updates properly

### After Testing
- [ ] All features work
- [ ] No crashes
- [ ] Persistence works
- [ ] Expiration works

---

## 📞 Quick Reference

**Files Modified:**
- `lib/app/services/ad_service.dart` (interstitial logic)
- `lib/app/services/storage_service.dart` (golden voice methods)
- `lib/app/modules/home/home_controller.dart` (timer + observables)
- `lib/app/modules/home/home_view.dart` (UI updates)

**Test Files:**
- `test/features_test.dart` (automated tests)
- `MANUAL_TEST_PLAN.md` (manual test steps)
- `VERIFICATION_SCRIPT.md` (verification guide)

**Ad Unit IDs (Test):**
- Interstitial Android: `ca-app-pub-3940256099942544/1033173712`
- Rewarded Android: `ca-app-pub-3940256099942544/5224354917`

