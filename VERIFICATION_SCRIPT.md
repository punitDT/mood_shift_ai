# 🔍 MoodShift AI - Complete Verification Script
## Quick Verification Guide for Both Features

---

## 📋 PRE-FLIGHT CHECKLIST

Before running tests, verify these are in place:

### Code Changes Implemented ✅
- [x] `ad_service.dart`: Changed `counter >= 4` to `counter == 4`
- [x] `ad_service.dart`: Added debug logging for shift counter
- [x] `storage_service.dart`: Added `getRemainingGoldenTime()` method
- [x] `storage_service.dart`: Added `getGoldenVoiceEndTime()` method
- [x] `storage_service.dart`: Added `clearGoldenVoice()` method
- [x] `storage_service.dart`: Added auto-clear on expiration
- [x] `home_controller.dart`: Added `hasGoldenVoice` observable
- [x] `home_controller.dart`: Added `goldenTimeRemaining` observable
- [x] `home_controller.dart`: Added `_goldenVoiceTimer` periodic timer
- [x] `home_controller.dart`: Added `_updateGoldenVoiceStatus()` method
- [x] `home_controller.dart`: Enhanced golden voice unlock with confetti
- [x] `home_view.dart`: Added golden mic glow animation
- [x] `home_view.dart`: Added timer display above mic
- [x] `home_view.dart`: Updated button text based on golden status

### Test Ad Unit IDs Configured ✅
- [x] Interstitial (Android): `ca-app-pub-3940256099942544/1033173712`
- [x] Interstitial (iOS): `ca-app-pub-3940256099942544/4411468910`
- [x] Rewarded (Android): `ca-app-pub-3940256099942544/5224354917`
- [x] Rewarded (iOS): `ca-app-pub-3940256099942544/1712485313`

---

## 🚀 QUICK START: 5-MINUTE VERIFICATION

### Step 1: Run Automated Tests (2 minutes)

```bash
# Run the automated test suite
flutter test test/features_test.dart -r expanded

# Expected output:
# ✅ All tests in "FEATURE 1: Interstitial Ad Counter Logic" pass
# ✅ All tests in "FEATURE 2: Golden Voice Timer Logic" pass
# ✅ Integration test passes
```

**What to look for:**
- All tests show green checkmarks ✅
- No red failures ❌
- Counter logic tests confirm ads only on 4th shift
- Timer tests confirm 1-hour duration and countdown

### Step 2: Quick Manual Test on Device (3 minutes)

```bash
# Build and run on device
flutter run --release
```

**Quick Test Sequence:**

1. **Test Interstitial (30 seconds)**
   - Complete 4 shifts quickly (say short phrases)
   - Verify interstitial ad shows ONLY on 4th shift
   - Check debug logs confirm counter values

2. **Test Golden Voice (2 minutes)**
   - Tap "Unlock Golden Voice 1 hour" button
   - Watch rewarded ad
   - Verify:
     - ✅ Mic turns gold with glow
     - ✅ Timer appears: "Golden: 59:XX"
     - ✅ Button text changes to "Golden Active – 59:XX"
   - Wait 10 seconds, verify timer counts down
   - Close and reopen app, verify timer persists

---

## 🧪 DETAILED VERIFICATION STEPS

### FEATURE 1: Interstitial Ad - Detailed Verification

#### Test 1A: Counter Increments Correctly
```
Action: Complete 7 shifts
Expected Debug Logs:
  Shift 1: 🎯 [AD DEBUG] Shift counter: 1
  Shift 2: 🎯 [AD DEBUG] Shift counter: 2
  Shift 3: 🎯 [AD DEBUG] Shift counter: 3
  Shift 4: 🎯 [AD DEBUG] Shift counter: 4
          ✅ [AD DEBUG] Showing interstitial ad on shift #4
  Shift 5: 🎯 [AD DEBUG] Shift counter: 1
  Shift 6: 🎯 [AD DEBUG] Shift counter: 2
  Shift 7: 🎯 [AD DEBUG] Shift counter: 3

Result: ✅ PASS / ❌ FAIL
```

#### Test 1B: Ad Shows Only on 4th
```
Action: Complete 8 shifts, observe when ad appears
Expected:
  Shift 1: No ad
  Shift 2: No ad
  Shift 3: No ad
  Shift 4: ✅ INTERSTITIAL AD SHOWS
  Shift 5: No ad
  Shift 6: No ad
  Shift 7: No ad
  Shift 8: ✅ INTERSTITIAL AD SHOWS

Result: ✅ PASS / ❌ FAIL
```

#### Test 1C: Counter Persists
```
Action: 
  1. Complete 2 shifts
  2. Force close app
  3. Reopen app
  4. Complete 2 more shifts (total = 4)
Expected:
  - Ad shows on 4th shift (not 2nd shift after restart)
  - Debug log shows counter = 2 after restart

Result: ✅ PASS / ❌ FAIL
```

---

### FEATURE 2: Golden Voice - Detailed Verification

#### Test 2A: Golden Voice Activation
```
Action: Tap "Unlock Golden Voice 1 hour", watch ad
Expected:
  ✅ Confetti animation plays
  ✅ Snackbar: "✨ Golden Voice Unlocked! 1 hour of premium warm voice activated"
  ✅ Debug log: ✨ [GOLDEN DEBUG] Golden Voice activated until: [timestamp]

Result: ✅ PASS / ❌ FAIL
```

#### Test 2B: UI Changes
```
Action: Observe UI after activation
Expected:
  ✅ Mic button has GOLD gradient (not purple)
  ✅ Mic has golden glow (larger, brighter shadow)
  ✅ Timer badge visible above mic
  ✅ Timer shows: "Golden: 59:XX"
  ✅ Star icon in timer badge
  ✅ Button text: "Golden Active – 59:XX"
  ✅ Button disabled (60% opacity, darker color)

Result: ✅ PASS / ❌ FAIL
```

#### Test 2C: Timer Countdown
```
Action: Watch timer for 60 seconds
Expected:
  ✅ Timer counts down every second
  ✅ Format stays MM:SS (e.g., 59:45, 59:44, 59:43...)
  ✅ Debug logs every second: ⏱️ [GOLDEN DEBUG] Time remaining: XX:XX

Result: ✅ PASS / ❌ FAIL
```

#### Test 2D: Voice Quality Change
```
Action: Complete a shift with golden voice active
Expected:
  ✅ Voice sounds warmer (higher pitch)
  ✅ Voice sounds slower (reduced rate)
  ✅ More pleasant, premium quality
  ✅ Noticeable difference from normal voice

Result: ✅ PASS / ❌ FAIL
```

#### Test 2E: Persistence
```
Action:
  1. Activate golden voice
  2. Note timer value (e.g., 47:23)
  3. Force close app
  4. Wait 10 seconds
  5. Reopen app
Expected:
  ✅ Golden glow still visible
  ✅ Timer shows ~47:13 (10 seconds less)
  ✅ Timer continues counting down
  ✅ Voice still uses golden settings

Result: ✅ PASS / ❌ FAIL
```

#### Test 2F: Expiration
```
Action: Wait 60 minutes OR change device time +1 hour
Expected:
  ✅ Golden glow disappears
  ✅ Mic returns to purple gradient
  ✅ Timer badge disappears
  ✅ Button text: "Unlock Golden Voice 1 hour"
  ✅ Button enabled (full opacity)
  ✅ Voice returns to normal settings
  ✅ Debug log: 🔄 [GOLDEN DEBUG] Golden Voice cleared

Result: ✅ PASS / ❌ FAIL
```

---

## 📊 VERIFICATION CHECKLIST

### Automated Tests
- [ ] Run `flutter test test/features_test.dart`
- [ ] All 15+ tests pass
- [ ] No errors or warnings
- [ ] Counter logic tests pass
- [ ] Timer logic tests pass
- [ ] Integration test passes

### Manual Tests - Feature 1
- [ ] Interstitial shows on 4th shift
- [ ] Interstitial shows on 8th shift
- [ ] No interstitial on 1st, 2nd, 3rd shifts
- [ ] No interstitial on 5th, 6th, 7th shifts
- [ ] Counter persists after app restart
- [ ] Debug logs show correct values

### Manual Tests - Feature 2
- [ ] Rewarded ad plays successfully
- [ ] Snackbar shows on unlock
- [ ] Confetti plays on unlock
- [ ] Mic turns gold with glow
- [ ] Timer appears and counts down
- [ ] Timer format is MM:SS
- [ ] Button text changes to "Golden Active"
- [ ] Button becomes disabled
- [ ] Voice sounds warmer/slower
- [ ] Timer persists after app restart
- [ ] Effects clear after 1 hour
- [ ] Can renew after expiration

---

## 🐛 TROUBLESHOOTING

### Issue: Automated tests fail
**Solution:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter test test/features_test.dart
```

### Issue: Ads don't load on device
**Possible causes:**
- No internet connection
- AdMob not initialized
- Test device not configured

**Solution:**
```bash
# Check logs for ad loading errors
adb logcat | grep -i "admob\|ad"  # Android
# or check Xcode console for iOS
```

### Issue: Golden voice timer not visible
**Check:**
- `hasGoldenVoice.value` is true
- `goldenTimeRemaining.value` is not empty
- Timer widget is in the UI tree

### Issue: Counter not persisting
**Check:**
- GetStorage is initialized
- `shift_counter` key exists in storage
- No errors in storage service

---

## ✅ FINAL VERIFICATION

### All Tests Must Pass:
1. ✅ Automated test suite: 100% pass rate
2. ✅ Interstitial shows ONLY on 4th, 8th, 12th shifts
3. ✅ Golden voice activates with all UI changes
4. ✅ Timer counts down accurately
5. ✅ Both features persist across app restarts
6. ✅ Golden voice expires after 1 hour
7. ✅ Debug logs confirm all behaviors

### Sign-Off:
```
Tested by: ___________________
Date: ___________________
Device: ___________________
OS Version: ___________________

Feature 1 (Interstitial): ✅ PASS / ❌ FAIL
Feature 2 (Golden Voice): ✅ PASS / ❌ FAIL

Overall: ✅ READY FOR PRODUCTION / ❌ NEEDS FIXES
```

---

## 📞 SUPPORT

If any tests fail or unexpected behavior occurs:

1. Check debug logs in console
2. Verify all code changes are applied
3. Clear app data and retry
4. Run automated tests first
5. Review MANUAL_TEST_PLAN.md for detailed steps

**Debug Log Locations:**
- Android: Android Studio → Logcat
- iOS: Xcode → Console
- Filter by: `[AD DEBUG]` or `[GOLDEN DEBUG]`

