# 🧪 MoodShift AI - Manual Test Plan
## Feature Testing: Interstitial Ads & Golden Voice

---

## ✅ FEATURE 1: INTERSTITIAL AD AFTER EXACTLY 4TH SHIFT

### Test Objective
Verify that interstitial ads show ONLY after the 4th, 8th, 12th, etc. successful shift, and NOT on any other shift numbers.

### Prerequisites
- App installed on real device (Android or iOS)
- Test ad units configured (already set in code)
- Clear app data before starting (to reset counter)

### Test Steps

#### Test Case 1.1: First 4 Shifts - Verify Ad Shows on 4th Only

1. **Clear App Data**
   - Android: Settings → Apps → MoodShift AI → Storage → Clear Data
   - iOS: Uninstall and reinstall app
   - **Expected**: Fresh start with counter = 0

2. **Perform 1st Shift**
   - Open app
   - Hold mic button and speak: "I feel stressed"
   - Wait for AI response and TTS to complete
   - **Expected**: 
     - ✅ Confetti animation plays
     - ✅ Reward buttons appear
     - ❌ NO interstitial ad shows
     - ✅ Debug log: `🎯 [AD DEBUG] Shift counter: 1`
     - ✅ Debug log: `⏭️ [AD DEBUG] Skipping interstitial (counter: 1, loaded: true)`

3. **Perform 2nd Shift**
   - Hold mic button and speak: "I'm feeling better"
   - Wait for completion
   - **Expected**: 
     - ❌ NO interstitial ad shows
     - ✅ Debug log: `🎯 [AD DEBUG] Shift counter: 2`

4. **Perform 3rd Shift**
   - Hold mic button and speak: "Tell me something positive"
   - Wait for completion
   - **Expected**: 
     - ❌ NO interstitial ad shows
     - ✅ Debug log: `🎯 [AD DEBUG] Shift counter: 3`

5. **Perform 4th Shift** ⭐ CRITICAL TEST
   - Hold mic button and speak: "I need motivation"
   - Wait for completion
   - **Expected**: 
     - ✅ **INTERSTITIAL AD SHOWS** (full screen test ad)
     - ✅ Debug log: `🎯 [AD DEBUG] Shift counter: 4`
     - ✅ Debug log: `✅ [AD DEBUG] Showing interstitial ad on shift #4`
     - ✅ After closing ad, counter resets to 0

#### Test Case 1.2: Shifts 5-8 - Verify Ad Shows on 8th Only

6. **Perform 5th Shift**
   - Speak any phrase
   - **Expected**: ❌ NO interstitial ad

7. **Perform 6th Shift**
   - Speak any phrase
   - **Expected**: ❌ NO interstitial ad

8. **Perform 7th Shift**
   - Speak any phrase
   - **Expected**: ❌ NO interstitial ad

9. **Perform 8th Shift** ⭐ CRITICAL TEST
   - Speak any phrase
   - **Expected**: 
     - ✅ **INTERSTITIAL AD SHOWS**
     - ✅ Counter resets to 0

#### Test Case 1.3: Persistence After App Restart

10. **Perform 2 Shifts**
    - Complete 2 shifts
    - **Expected**: Counter = 2, no ad

11. **Close App Completely**
    - Force close the app (swipe away from recent apps)
    - Wait 5 seconds

12. **Reopen App**
    - Launch app again
    - **Expected**: App opens normally

13. **Perform 2 More Shifts**
    - Complete 2 shifts (total = 4)
    - **Expected**: 
      - ✅ On 4th shift, interstitial ad shows
      - ✅ Counter persisted correctly across app restart

---

## ✅ FEATURE 2: UNLOCK GOLDEN VOICE 1 HOUR (REWARDED AD)

### Test Objective
Verify Golden Voice unlocks for 1 hour after watching rewarded ad, with proper UI updates, timer countdown, voice changes, and persistence.

### Prerequisites
- App installed on real device
- Complete at least 1 shift to see reward buttons

### Test Steps

#### Test Case 2.1: Unlock Golden Voice

1. **Complete 1 Shift**
   - Perform any shift to show reward buttons
   - **Expected**: 3 reward buttons visible

2. **Check Initial State**
   - Observe mic button
   - **Expected**: 
     - ✅ Mic has purple/deep purple gradient
     - ✅ No golden glow
     - ✅ No timer visible
     - ✅ Button text: "Unlock Golden Voice 1 hour"

3. **Tap "Unlock Golden Voice 1 hour" Button**
   - Tap the golden voice button (star icon)
   - **Expected**: 
     - ✅ Rewarded ad loads and shows (test ad)

4. **Watch Rewarded Ad Completely**
   - Watch the test ad to completion
   - Close the ad
   - **Expected**: 
     - ✅ Confetti animation plays
     - ✅ Snackbar appears: "✨ Golden Voice Unlocked! 1 hour of premium warm voice activated"
     - ✅ Debug log: `✨ [GOLDEN DEBUG] Golden Voice activated until: [timestamp]`

#### Test Case 2.2: Verify Golden Voice UI Changes

5. **Check Mic Button Appearance**
   - Observe the mic button
   - **Expected**: 
     - ✅ Mic has **GOLD gradient** (gold to orange)
     - ✅ **Golden glow/sparkle** effect (larger, brighter shadow)
     - ✅ Extra yellow sparkle shadow visible

6. **Check Timer Display**
   - Look above the mic button
   - **Expected**: 
     - ✅ Timer badge visible with gold gradient background
     - ✅ Text shows: "Golden: 59:XX" (counting down)
     - ✅ Star icon next to timer
     - ✅ Timer updates every second

7. **Check Button State**
   - Look at the golden voice button in reward section
   - **Expected**: 
     - ✅ Button text changed to: "Golden Active – 59:XX"
     - ✅ Button appears disabled (60% opacity)
     - ✅ Button darker amber color
     - ✅ Cannot tap button again

#### Test Case 2.3: Verify Voice Changes

8. **Perform a Shift with Golden Voice**
   - Hold mic and speak: "Tell me something calming"
   - Listen to the TTS response
   - **Expected**: 
     - ✅ Voice sounds **warmer and slower**
     - ✅ Speech rate: 0.9x of normal (10% slower)
     - ✅ Pitch: 1.1x of normal (10% higher/warmer)
     - ✅ More pleasant, premium quality feel

9. **Compare with Normal Voice (Optional)**
   - Remember how the voice sounded before
   - **Expected**: Noticeable difference in warmth and pace

#### Test Case 2.4: Timer Countdown

10. **Wait 1 Minute**
    - Observe the timer for 60 seconds
    - **Expected**: 
      - ✅ Timer counts down: 59:59 → 59:58 → ... → 59:00
      - ✅ Debug logs every second: `⏱️ [GOLDEN DEBUG] Time remaining: XX:XX`

11. **Check Timer Accuracy**
    - Use phone stopwatch to verify
    - **Expected**: Timer is accurate (±1 second)

#### Test Case 2.5: Persistence After App Restart

12. **Note Current Timer Value**
    - Example: Timer shows "Golden: 47:23"
    - Write down the time

13. **Close App Completely**
    - Force close the app
    - Wait 10 seconds

14. **Reopen App**
    - Launch app again
    - **Expected**: 
      - ✅ Golden voice still active
      - ✅ Mic still has golden glow
      - ✅ Timer shows approximately "Golden: 47:13" (10 seconds less)
      - ✅ Timer continues counting down

15. **Perform a Shift**
    - Complete a shift
    - **Expected**: 
      - ✅ Voice still uses golden/premium settings
      - ✅ Timer still visible and counting

#### Test Case 2.6: Timer Expiration

16. **Fast-Forward Time (Optional - Advanced)**
    - **Option A**: Wait full 60 minutes (recommended for thorough test)
    - **Option B**: Change device time forward by 1 hour
      - Settings → Date & Time → Set time +1 hour
      - Return to app

17. **Check After Expiration**
    - **Expected**: 
      - ✅ Golden glow **disappears** from mic
      - ✅ Mic returns to **purple gradient**
      - ✅ Timer badge **disappears**
      - ✅ Button text returns to: "Unlock Golden Voice 1 hour"
      - ✅ Button enabled again (full opacity)
      - ✅ Debug log: `🔄 [GOLDEN DEBUG] Golden Voice cleared`

18. **Perform a Shift After Expiration**
    - Complete a shift
    - **Expected**: 
      - ✅ Voice returns to **normal** settings (no golden effect)
      - ✅ Normal speech rate and pitch

#### Test Case 2.7: Renew Golden Voice

19. **Unlock Golden Voice Again**
    - Tap "Unlock Golden Voice 1 hour" button
    - Watch rewarded ad
    - **Expected**: 
      - ✅ Golden voice activates again
      - ✅ Timer resets to 59:59
      - ✅ All golden effects return

---

## 🐛 KNOWN ISSUES TO VERIFY ARE FIXED

### Issue 1: Interstitial Showing on Every Shift After 4th
- **Bug**: Old code used `counter >= 4`, causing ads on 5th, 6th, 7th shifts
- **Fix**: Changed to `counter == 4`
- **Verify**: Ads ONLY on 4th, 8th, 12th (not 5th, 6th, 7th, etc.)

### Issue 2: Golden Voice Timer Not Visible
- **Bug**: No UI to show remaining time
- **Fix**: Added timer badge above mic button
- **Verify**: Timer visible and counting down

### Issue 3: Golden Voice Not Persisting
- **Bug**: Timer lost on app restart
- **Fix**: Timer stored in GetStorage with ISO timestamp
- **Verify**: Timer persists across app restarts

---

## 📊 TEST RESULTS CHECKLIST

### Feature 1: Interstitial Ads
- [ ] Ad shows on 4th shift
- [ ] Ad does NOT show on 1st, 2nd, 3rd shifts
- [ ] Ad shows on 8th shift
- [ ] Ad does NOT show on 5th, 6th, 7th shifts
- [ ] Counter persists after app restart
- [ ] Debug logs show correct counter values

### Feature 2: Golden Voice
- [ ] Rewarded ad plays successfully
- [ ] Snackbar shows success message
- [ ] Mic button turns gold with glow
- [ ] Timer appears and counts down
- [ ] Timer shows correct format (MM:SS)
- [ ] Button text changes to "Golden Active – XX:XX"
- [ ] Button becomes disabled during active period
- [ ] Voice sounds warmer/slower during golden period
- [ ] Timer persists after app restart
- [ ] Golden effects disappear after 1 hour
- [ ] Voice returns to normal after expiration
- [ ] Can unlock golden voice again after expiration

---

## 🔍 DEBUG LOG REFERENCE

### Expected Debug Logs

**Shift Counter:**
```
🎯 [AD DEBUG] Shift counter: 1
⏭️ [AD DEBUG] Skipping interstitial (counter: 1, loaded: true)
```

**Interstitial Ad (4th shift):**
```
🎯 [AD DEBUG] Shift counter: 4
✅ [AD DEBUG] Showing interstitial ad on shift #4
```

**Golden Voice Activation:**
```
✨ [GOLDEN DEBUG] Golden Voice activated until: 2025-11-22 15:30:00.000
```

**Golden Voice Timer:**
```
⏱️ [GOLDEN DEBUG] Time remaining: 59:45
⏱️ [GOLDEN DEBUG] Time remaining: 59:44
```

**Golden Voice Cleared:**
```
🔄 [GOLDEN DEBUG] Golden Voice cleared
```

---

## ✅ PASS CRITERIA

**Feature 1 PASSES if:**
- Interstitial ad shows ONLY on 4th, 8th, 12th shifts
- Counter persists across app restarts
- Debug logs confirm correct behavior

**Feature 2 PASSES if:**
- Golden voice unlocks after watching ad
- Timer displays and counts down accurately
- Mic shows golden glow during active period
- Voice quality changes are noticeable
- Timer persists across app restarts
- All effects clear after 1 hour
- Can be renewed after expiration

---

## 📝 NOTES

- Use **real device** for testing (emulator may have ad loading issues)
- Ensure **internet connection** for ads to load
- Test ads are configured in code (no changes needed)
- Debug logs visible in Android Studio Logcat or Xcode Console
- For faster testing, use device time manipulation for timer expiration test

