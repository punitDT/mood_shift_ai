# Testing Guide - Polly Generative Upgrade

## 🧪 How to Test the Implementation

### Test 1: First Launch Voice Discovery

**Steps:**
1. Clear app data or use a fresh install
2. Launch the app
3. Check console logs for voice discovery

**Expected Output:**
```
🔍 [POLLY] First launch detected - starting voice discovery...
🔍 [POLLY] Calling DescribeVoices API...
✅ [POLLY] Found 127 total voices
🎙️ [POLLY] en-US voices:
   Generative: M=Matthew, F=Danielle
   Neural: M=Matthew, F=Joanna
   Standard: M=Joey, F=Joanna
🧪 [POLLY] Starting voice test suite...
✅ [POLLY] en-US female → Generative OK (Danielle)
✅ [POLLY] en-US male → Generative OK (Matthew)
...
🎉 [POLLY] Voice Test Complete:
   Generative ready: 15/16 voices
   Neural fallback: 1 voices
   Standard fallback: 0 voices
✅ [POLLY] Voice discovery complete!
✅ [STORAGE] Polly voice map saved (8 languages)
```

**Pass Criteria:**
- ✅ Voice discovery completes without errors
- ✅ All 8 languages have voices mapped
- ✅ Test suite runs and reports results
- ✅ Voice map saved to storage

---

### Test 2: Subsequent Launch (Cached Voice Map)

**Steps:**
1. Close and relaunch the app
2. Check console logs

**Expected Output:**
```
✅ [POLLY] Voice map loaded from storage (8 languages)
```

**Pass Criteria:**
- ✅ Voice map loads from storage instantly
- ✅ No API calls made
- ✅ App starts faster

---

### Test 3: Main Mode Speech (Normal)

**Steps:**
1. Select any language
2. Select any gender (male/female)
3. Speak a phrase in Main mode
4. Check console logs

**Expected Output:**
```
🎙️ [POLLY] Selected voice from map: Danielle (generative) for en-US (female)
🎙️ [POLLY] Synthesizing with voice: Danielle, language: en-US (NORMAL mode)
✅ [POLLY] Audio synthesized successfully with generative engine
```

**Pass Criteria:**
- ✅ Uses generative engine
- ✅ Speech sounds natural and human-like
- ✅ No errors

---

### Test 4: Golden Voice Mode

**Steps:**
1. Activate Golden Voice (watch rewarded ad)
2. Speak a phrase
3. Check console logs

**Expected Output:**
```
🎙️ [POLLY] Selected voice from map: Danielle (generative) for en-US (female)
🎙️ [POLLY] Synthesizing with voice: Danielle, language: en-US (GOLDEN mode)
✅ [POLLY] Audio synthesized successfully with generative engine
```

**Pass Criteria:**
- ✅ Uses generative engine
- ✅ Speech sounds **insanely human-like** (slow, warm, rich)
- ✅ Premium SSML effects applied (DRC, soft phonation, vocal tract length)
- ✅ No errors

---

### Test 5: 2× Stronger Mode

**Steps:**
1. Toggle 2× Stronger ON
2. Speak a phrase
3. Check console logs

**Expected Output:**
```
⚡ [POLLY] Synthesizing 2× STRONGER with voice: Danielle, language: en-US
✅ [POLLY] 2× STRONGER audio synthesized successfully with generative engine
```

**Pass Criteria:**
- ✅ Uses generative engine
- ✅ Speech is **fast, loud, and energetic**
- ✅ Strong emphasis applied
- ✅ No errors

---

### Test 6: Multi-Language Support

**Steps:**
1. Test each of the 8 languages:
   - English (US)
   - English (UK)
   - Hindi
   - Spanish
   - Chinese
   - French
   - German
   - Arabic
   - Japanese
2. Check console logs for each

**Expected Output (per language):**
```
🎙️ [POLLY] Selected voice from map: [VoiceId] (generative) for [lang] (female)
✅ [POLLY] Audio synthesized successfully with generative engine
```

**Pass Criteria:**
- ✅ All 8 languages work
- ✅ Generative engine used when available
- ✅ Fallback to neural/standard when needed
- ✅ No crashes

---

### Test 7: Engine Fallback Chain

**Steps:**
1. Temporarily modify `.env` to use invalid AWS credentials
2. Speak a phrase
3. Check console logs

**Expected Output:**
```
❌ [POLLY] Polly synthesis failed: [error]
🔄 [POLLY] Using flutter_tts fallback
```

**Pass Criteria:**
- ✅ App doesn't crash
- ✅ Falls back to flutter_tts
- ✅ Speech still works (offline mode)

---

### Test 8: Voice Gender Switching

**Steps:**
1. Switch between male and female voices
2. Speak phrases with each
3. Check console logs

**Expected Output:**
```
🎙️ [POLLY] Selected voice from map: Matthew (generative) for en-US (male)
✅ [POLLY] Audio synthesized successfully with generative engine

🎙️ [POLLY] Selected voice from map: Danielle (generative) for en-US (female)
✅ [POLLY] Audio synthesized successfully with generative engine
```

**Pass Criteria:**
- ✅ Male and female voices work
- ✅ Both use generative engine
- ✅ Distinct voice characteristics

---

### Test 9: Caching System

**Steps:**
1. Speak the same phrase twice
2. Check console logs

**Expected Output (first time):**
```
🎙️ [POLLY] Synthesizing with voice: Danielle, language: en-US (NORMAL mode)
✅ [POLLY] Audio synthesized successfully with generative engine
```

**Expected Output (second time):**
```
🎵 [POLLY] Using cached audio
```

**Pass Criteria:**
- ✅ First request synthesizes audio
- ✅ Second request uses cache
- ✅ Instant playback on cache hit

---

### Test 10: Force Re-Discovery

**Steps:**
1. Run this code in debug console:
   ```dart
   Get.find<StorageService>().clearPollyVoiceMap();
   ```
2. Restart the app
3. Check console logs

**Expected Output:**
```
🔍 [POLLY] First launch detected - starting voice discovery...
[... full discovery process ...]
✅ [POLLY] Voice discovery complete!
```

**Pass Criteria:**
- ✅ Voice discovery runs again
- ✅ New voice map saved
- ✅ All voices re-tested

---

## 🎯 Success Criteria Summary

### Must Pass:
- ✅ Voice discovery completes on first launch
- ✅ Voice map persists across app restarts
- ✅ Generative engine used whenever possible
- ✅ Multi-level fallback works (generative → neural → standard → flutter_tts)
- ✅ All 8 languages work
- ✅ All 3 modes work (Main, 2× Stronger, Golden Voice)
- ✅ Male and female voices work
- ✅ App never crashes (always produces speech)

### Quality Checks:
- ✅ Golden Voice sounds **insanely human-like** with generative
- ✅ 2× Stronger is **noticeably more energetic**
- ✅ Main mode sounds **natural and clear**
- ✅ Caching improves performance
- ✅ Detailed logging helps debugging

---

## 🐛 Troubleshooting

### Issue: Voice discovery fails
**Solution:** Check AWS credentials in `.env` file

### Issue: No generative voices found
**Solution:** Ensure region is set to `us-east-1` in `.env`

### Issue: Speech sounds robotic
**Solution:** Check console logs - may be using standard engine fallback

### Issue: App crashes on first launch
**Solution:** Check internet connection - DescribeVoices API requires network

---

## 📝 Debug Commands

### View current voice map:
```dart
final storage = Get.find<StorageService>();
final voiceMap = storage.getPollyVoiceMap();
print(voiceMap);
```

### Clear voice map (force re-discovery):
```dart
Get.find<StorageService>().clearPollyVoiceMap();
// Restart app
```

### Check if voice map exists:
```dart
final voiceMap = Get.find<StorageService>().getPollyVoiceMap();
print('Voice map exists: ${voiceMap != null}');
```

---

**Happy Testing! 🎉**

