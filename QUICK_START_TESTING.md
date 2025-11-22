# ⚡ Quick Start Testing Guide
## Test Both Features in 10 Minutes

---

## 🎯 GOAL

Verify that:
1. ✅ Interstitial ad shows ONLY on 4th, 8th, 12th shifts
2. ✅ Golden Voice unlocks for 1 hour with timer and visual effects

---

## 📋 PREREQUISITES (1 minute)

```bash
# 1. Ensure code is up to date
git pull

# 2. Clean build
flutter clean
flutter pub get

# 3. Build for device
flutter run --release
```

**Device Requirements:**
- Real Android or iOS device (not emulator)
- Internet connection (for ads)
- Clear app data before testing

---

## 🧪 AUTOMATED TESTS (2 minutes)

### Run the Test Suite

```bash
flutter test test/features_test.dart -r expanded
```

### Expected Output

```
✅ FEATURE 1: Interstitial Ad Counter Logic
  ✅ Counter starts at 0
  ✅ Counter increments correctly for 7 shifts
  ✅ Interstitial should show ONLY on 4th shift
  ✅ Counter persists across service restarts
  ✅ Counter resets correctly after 4th shift
  ✅ Verify counter never shows ad on 1st, 2nd, 3rd, 5th, 6th, 7th shifts

✅ FEATURE 2: Golden Voice Timer Logic
  ✅ Golden voice initially inactive
  ✅ Golden voice activates for 1 hour
  ✅ Golden voice timer counts down
  ✅ Golden voice timer format is correct
  ✅ Golden voice persists across service restarts
  ✅ Golden voice expires after 1 hour
  ✅ Golden voice can be renewed after expiration
  ✅ Clear golden voice works correctly

✅ INTEGRATION: Both Features Together
  ✅ Simulate 4 shifts with golden voice unlock on 4th

All tests passed! ✅
```

**If all tests pass → Continue to manual testing**
**If any test fails → Check DEBUG_REFERENCE.md**

---

## 📱 MANUAL TESTING (7 minutes)

### PART 1: Interstitial Ad (3 minutes)

#### Step 1: Clear App Data
- Android: Settings → Apps → MoodShift AI → Storage → Clear Data
- iOS: Uninstall and reinstall

#### Step 2: Complete 4 Shifts
Open app and complete 4 shifts quickly:

```
Shift 1: "I feel stressed"        → ❌ No ad
Shift 2: "I'm feeling better"     → ❌ No ad
Shift 3: "Tell me something"      → ❌ No ad
Shift 4: "I need motivation"      → ✅ INTERSTITIAL AD SHOWS
```

#### Step 3: Verify Debug Logs
Check console for:
```
🎯 [AD DEBUG] Shift counter: 1
🎯 [AD DEBUG] Shift counter: 2
🎯 [AD DEBUG] Shift counter: 3
🎯 [AD DEBUG] Shift counter: 4
✅ [AD DEBUG] Showing interstitial ad on shift #4
```

#### Step 4: Test Persistence
```
1. Complete 2 more shifts (counter = 2)
2. Close app completely
3. Reopen app
4. Complete 2 more shifts (counter = 4)
5. Verify: Ad shows on 4th shift (not 2nd after restart)
```

**✅ PASS if:**
- Ad shows ONLY on 4th shift
- No ad on 1st, 2nd, 3rd shifts
- Counter persists after restart

---

### PART 2: Golden Voice (4 minutes)

#### Step 1: Unlock Golden Voice
```
1. Complete 1 shift (to show reward buttons)
2. Tap "Unlock Golden Voice 1 hour" button
3. Watch test rewarded ad to completion
4. Close ad
```

#### Step 2: Verify Immediate Effects
**Check these appear instantly:**

✅ **Confetti Animation**
- Confetti particles explode from top

✅ **Snackbar Message**
- Text: "✨ Golden Voice Unlocked! 1 hour of premium warm voice activated"
- Amber background
- Star icon

✅ **Mic Button Changes**
- Color: Gold gradient (not purple)
- Glow: Larger, golden sparkle effect
- Very noticeable difference

✅ **Timer Appears**
- Badge above mic button
- Text: "Golden: 59:XX"
- Star icon in badge
- Gold gradient background

✅ **Button State Changes**
- Text: "Golden Active – 59:XX"
- Disabled (60% opacity)
- Darker amber color

#### Step 3: Verify Timer Countdown (1 minute)
```
1. Watch timer for 60 seconds
2. Verify it counts down: 59:59 → 59:58 → 59:57...
3. Check format stays MM:SS
```

**Debug logs should show:**
```
✨ [GOLDEN DEBUG] Golden Voice activated until: [timestamp]
⏱️  [GOLDEN DEBUG] Time remaining: 59:45
⏱️  [GOLDEN DEBUG] Time remaining: 59:44
```

#### Step 4: Verify Voice Quality
```
1. Complete a shift while golden voice is active
2. Listen to TTS response
3. Voice should sound:
   - Warmer (higher pitch)
   - Slower (reduced rate)
   - More pleasant/premium
```

#### Step 5: Verify Persistence
```
1. Note current timer (e.g., "Golden: 47:23")
2. Close app completely
3. Wait 10 seconds
4. Reopen app
5. Verify:
   - Golden glow still visible
   - Timer shows ~47:13 (10 seconds less)
   - Timer continues counting down
```

**✅ PASS if:**
- All visual effects appear
- Timer counts down accurately
- Voice sounds different
- Timer persists after restart

---

## 🎯 QUICK VERIFICATION CHECKLIST

### Feature 1: Interstitial Ad
- [ ] Ad shows on 4th shift
- [ ] No ad on 1st, 2nd, 3rd shifts
- [ ] Counter persists after app restart
- [ ] Debug logs show correct counter values

### Feature 2: Golden Voice
- [ ] Rewarded ad plays successfully
- [ ] Confetti + snackbar appear
- [ ] Mic turns gold with glow
- [ ] Timer appears: "Golden: 59:XX"
- [ ] Timer counts down every second
- [ ] Button text: "Golden Active – XX:XX"
- [ ] Button disabled during active period
- [ ] Voice sounds warmer/slower
- [ ] Timer persists after app restart

---

## 🐛 TROUBLESHOOTING

### Automated Tests Fail
```bash
flutter clean
flutter pub get
flutter test test/features_test.dart
```

### Ads Don't Load
- Check internet connection
- Verify test ad IDs in code
- Check console for ad loading errors

### Timer Not Visible
- Verify golden voice unlocked (check debug logs)
- Check `hasGoldenVoice.value` is true
- Restart app

### Counter Not Working
- Clear app data
- Check debug logs for counter values
- Verify GetStorage initialized

---

## 📊 EXPECTED RESULTS

### All Tests Pass ✅
```
Automated Tests: 15/15 passed
Manual Tests: All features work correctly
Debug Logs: Show correct behavior
```

### Ready for Production ✅
- Interstitial shows only on 4th, 8th, 12th shifts
- Golden voice unlocks with full UI effects
- Timer counts down and persists
- Voice quality changes are noticeable

---

## 📞 NEXT STEPS

### If All Tests Pass ✅
1. Review `IMPLEMENTATION_SUMMARY.md` for details
2. Deploy to production
3. Monitor analytics for ad impressions

### If Any Test Fails ❌
1. Check `DEBUG_REFERENCE.md` for troubleshooting
2. Review `MANUAL_TEST_PLAN.md` for detailed steps
3. Check debug logs for error messages
4. Verify all code changes applied

---

## 📁 DOCUMENTATION

**Quick Reference:**
- `QUICK_START_TESTING.md` ← You are here
- `IMPLEMENTATION_SUMMARY.md` - Complete overview
- `MANUAL_TEST_PLAN.md` - Detailed test cases
- `VERIFICATION_SCRIPT.md` - Verification guide
- `DEBUG_REFERENCE.md` - Debug help

**Test Files:**
- `test/features_test.dart` - Automated tests

**Modified Code:**
- `lib/app/services/ad_service.dart`
- `lib/app/services/storage_service.dart`
- `lib/app/modules/home/home_controller.dart`
- `lib/app/modules/home/home_view.dart`

---

## ✅ SUCCESS CRITERIA

**Both features work 100% correctly if:**

1. ✅ Automated tests: 15/15 pass
2. ✅ Interstitial shows ONLY on 4th, 8th, 12th shifts
3. ✅ Golden voice unlocks with all visual effects
4. ✅ Timer displays and counts down accurately
5. ✅ Both features persist across app restarts
6. ✅ Debug logs confirm correct behavior

**Total Testing Time: ~10 minutes**
**Expected Result: All features working perfectly** 🎉

