# 🚀 Quick Start Testing Guide - Rewarded Features

## Prerequisites

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Verify `.env` file has required keys:**
   ```env
   # Groq LLM API
   GROQ_API_KEY=your_groq_api_key_here
   
   # AWS Polly TTS
   AWS_ACCESS_KEY_ID=your_aws_access_key
   AWS_SECRET_ACCESS_KEY=your_aws_secret_key
   AWS_REGION=us-east-1
   
   # AdMob Test IDs (already configured)
   ADMOB_ANDROID_REWARDED_AD_UNIT_ID=ca-app-pub-3940256099942544/5224354917
   ADMOB_IOS_REWARDED_AD_UNIT_ID=ca-app-pub-3940256099942544/1712485313
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

---

## ⚡ Test 2× Stronger Feature (5 minutes)

### Step 1: Complete a Mood Shift
1. Hold the mic button
2. Say something like: "I'm feeling tired and unmotivated"
3. Release the mic button
4. Wait for AI response to play

### Step 2: Use 2× Stronger
1. Bottom sheet appears with "2× Stronger (3 left)" button
2. Tap the button
3. **Watch the test rewarded ad** (it's a test ad, so it's quick)
4. Ad closes automatically

### Step 3: Verify Visual Effects ✅
- [ ] Orange flash covers screen briefly
- [ ] "⚡ 2× POWER ACTIVATED! ⚡" overlay appears in center
- [ ] Confetti animation plays
- [ ] Button now shows "2× Stronger (2 left)"

### Step 4: Verify Audio Response ✅
- [ ] New response is generated (different from original)
- [ ] Response has more caps, emojis, exclamation marks
- [ ] Voice is noticeably faster, higher pitch, louder
- [ ] Response feels "2× stronger" in energy

### Step 5: Test Usage Limit ✅
1. Complete 2 more mood shifts
2. Use 2× Stronger on each (watch 2 more ads)
3. Complete a 4th mood shift
4. Tap "2× Stronger (0 left)" button
5. **Verify:** Snackbar appears: "⚡ Limit Reached"
6. **Verify:** No ad is shown

---

## ✨ Test Golden Voice Feature (5 minutes)

### Step 1: Activate Golden Voice
1. Complete a mood shift
2. Bottom sheet appears with "Golden Voice" button
3. Tap the button
4. **Watch the test rewarded ad**
5. Ad closes automatically

### Step 2: Verify Visual Effects ✅
- [ ] Golden sparkle animation plays (or golden glow fallback)
- [ ] "✨ Golden Voice Unlocked!" snackbar appears
- [ ] Golden timer appears in top-left: "Golden: 59:59"
- [ ] Timer counts down every second
- [ ] Mic button has golden glow effect

### Step 3: Verify Audio Quality ✅
1. Complete another mood shift
2. Listen to the response
3. **Verify:**
   - [ ] Voice sounds warmer and more empathetic
   - [ ] Voice is slightly slower than normal
   - [ ] Voice has conversational style
   - [ ] Voice feels more premium

### Step 4: Test Persistence ✅
1. Complete 2-3 more mood shifts
2. **Verify:**
   - [ ] Golden voice is used for all shifts
   - [ ] Timer continues counting down
   - [ ] Golden glow remains on mic button

---

## 🎨 Test Visual Effects (2 minutes)

### Orange Flash (2× Stronger)
1. Use 2× Stronger
2. **Verify:**
   - [ ] Orange flash covers entire screen
   - [ ] Flash lasts ~300ms
   - [ ] Flash has 30% opacity
   - [ ] Flash disappears smoothly

### Power Overlay (2× Stronger)
1. Use 2× Stronger
2. **Verify:**
   - [ ] "⚡ 2× POWER ACTIVATED! ⚡" overlay appears
   - [ ] Overlay is centered on screen
   - [ ] Overlay has orange background with glow
   - [ ] Overlay shows for ~1.5 seconds

### Golden Sparkle Animation
1. Activate golden voice
2. **Verify:**
   - [ ] Sparkle animation plays (or golden glow fallback)
   - [ ] Animation is centered on screen
   - [ ] Animation plays for ~2 seconds
   - [ ] Animation doesn't repeat

### Golden Glow on Mic Button
1. Activate golden voice
2. **Verify:**
   - [ ] Mic button has golden gradient
   - [ ] Glow is visible and attractive
   - [ ] Glow persists while golden voice is active

### Confetti Animation
1. Use 2× Stronger OR activate golden voice
2. **Verify:**
   - [ ] Confetti animation plays
   - [ ] Confetti is visible and celebratory
   - [ ] Confetti plays for ~3 seconds

---

## 📊 Test Analytics (Optional - 3 minutes)

### Enable Firebase Analytics Debug Mode

**Android:**
```bash
adb shell setprop debug.firebase.analytics.app com.moodshift.ai
```

**iOS:**
In Xcode, add `-FIRAnalyticsDebugEnabled` to launch arguments.

### Verify Events

1. Use 2× Stronger
2. Check console for:
   ```
   [Analytics] rewarded_ad_watched: {ad_type: stronger, reward_earned: 1}
   [Analytics] stronger_used: {timestamp: 2024-...}
   ```

3. Activate golden voice
4. Check console for:
   ```
   [Analytics] rewarded_ad_watched: {ad_type: golden_voice, reward_earned: 1}
   [Analytics] golden_voice_activated: {duration_minutes: 60, activation_time: 2024-...}
   ```

---

## 🐛 Common Issues & Fixes

### Issue: Ads not showing
**Fix:**
- Check internet connection
- Verify AdMob test IDs in `.env`
- Check console for ad load errors
- Wait a few seconds and try again

### Issue: 2× Stronger sounds normal
**Fix:**
- Check Groq API key in `.env`
- Verify LLM service is initialized
- Check console for API errors
- Try again with a different input

### Issue: Golden voice sounds normal
**Fix:**
- Verify Polly credentials in `.env`
- Check if golden voice is actually active (timer visible?)
- Verify SSML is being applied (check logs)
- Try restarting the app

### Issue: Timer not counting down
**Fix:**
- Check if timer is started in `onInit()`
- Verify storage methods are working
- Check console for timer errors
- Try restarting the app

### Issue: Visual effects not showing
**Fix:**
- Check if `RewardedController` is initialized
- Verify `Obx()` widgets are wrapping the effects
- Check console for errors
- Try restarting the app

---

## ✅ Final Checklist

Before considering the feature complete, verify:

### 2× Stronger
- [ ] Ad shows and rewards user
- [ ] Orange flash appears
- [ ] Power overlay appears
- [ ] Confetti plays
- [ ] New response is generated
- [ ] Voice is amplified (faster, higher, louder)
- [ ] Usage limit works (3/session)
- [ ] Button updates correctly
- [ ] Analytics events logged

### Golden Voice
- [ ] Ad shows and rewards user
- [ ] Sparkle animation plays
- [ ] Timer appears and counts down
- [ ] Mic button has golden glow
- [ ] Voice is warmer and empathetic
- [ ] Feature persists across shifts
- [ ] Timer expires correctly
- [ ] Analytics events logged

### Visual Effects
- [ ] Orange flash (2× stronger)
- [ ] Power overlay (2× stronger)
- [ ] Golden sparkle (golden voice)
- [ ] Golden glow (golden voice)
- [ ] Confetti (both features)

### Edge Cases
- [ ] Ad fails to load → retry works
- [ ] LLM API fails → fallback works
- [ ] Caching works correctly
- [ ] App restart preserves state
- [ ] Session reset works (next day)

---

## 🎉 Success!

If all tests pass, the rewarded features are **100% working, beautiful, and addictive**!

Users should be **spamming these buttons happily** because:
1. ✅ Visual effects are **magical** (flash, overlay, sparkle, glow)
2. ✅ Audio quality is **noticeably better** (2× stronger + golden voice)
3. ✅ Rewards are **instant** (no waiting)
4. ✅ Limits create **urgency** (3/day for 2× stronger)
5. ✅ Timer creates **engagement** (golden voice countdown)
6. ✅ Analytics track **everything** (for profit optimization)

---

Made with ❤️ for MoodShift AI

