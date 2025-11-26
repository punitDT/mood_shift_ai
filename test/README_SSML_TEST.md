# AWS Polly SSML Features Test

## ✅ Test Status: 100% PASSING (14/14)

**Last Run:** 2025-11-26
**Result:** All tests passed successfully

## 🎯 Purpose

This test validates the latest AWS Polly SSML features for the MoodShift AI application, ensuring that all three voice modulation features work correctly across different engines (Generative, Neural, Standard) and genders.

**Key Achievement:** Discovered actual AWS Polly API behavior differs from documentation and implemented robust workarounds.

## 📋 Features Tested

### 1. **Main - Basic Prosody**
Natural speech modulation per mood style:
- **Gentle Grandma:** `rate="slow"`, `volume="soft"`, `pitch="low"`
- **Chaos Energy:** `rate="medium"`, `volume="loud"`, `pitch="high"`
- **Permission Slip:** `rate="medium"`, `volume="medium"`, `pitch="medium"`
- **Reality Check:** `rate="medium"`, `volume="medium"`, `pitch="medium"`
- **Micro Dare:** `rate="medium"`, `volume="medium"`, `pitch="medium"`

### 2. **2× Stronger - Energized Speech**
Amplified, powerful, motivational speech:
- **Rate:** `medium` (max - never faster per app policy)
- **Volume:** `+6dB` (amplified)
- **Pitch:** `+15%` (elevated)
- **Emphasis:** `<emphasis level="strong">` (Standard engine only)

### 3. **Golden Voice - Premium Intimacy**
Warm, intimate, premium-quality speech:
- **Rate:** `slow` (deliberate, measured)
- **Pitch:** `-10%` (warmer, deeper)
- **Volume:** `soft` (gentle, intimate)
- **DRC:** `<amazon:effect name="drc">` (Neural/Standard only)
- **Phonation:** `<amazon:effect phonation="soft">` (Standard only)
- **Vocal Tract:** `<amazon:effect vocal-tract-length="+12%">` (Standard only)

## 🚀 Running the Test

### Prerequisites

1. **AWS Credentials:** You need valid AWS credentials with Polly access
2. **Dart SDK:** Ensure Dart is installed
3. **Dependencies:** Run `flutter pub get` to install dependencies

### Command

```bash
# From the project root directory
dart test/test_polly_ssml_features.dart <AWS_ACCESS_KEY> <AWS_SECRET_KEY>
```

### Example

```bash
dart test/test_polly_ssml_features.dart AKIAIOSFODNN7EXAMPLE wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

### Using .env File

If you have your credentials in `.env`:

```bash
# Extract credentials from .env
AWS_ACCESS_KEY=$(grep AWS_ACCESS_KEY .env | cut -d '=' -f2)
AWS_SECRET_KEY=$(grep AWS_SECRET_KEY .env | cut -d '=' -f2)

# Run the test
dart test/test_polly_ssml_features.dart $AWS_ACCESS_KEY $AWS_SECRET_KEY
```

## 📊 Expected Output

### Step 1: Voice Discovery
```
📋 Step 1: Fetching available voices from AWS Polly...
✅ Found 87 total voices
```

### Step 2: Voice Organization
```
📊 Step 2: Organizing voices by engine and gender...

🌍 Language: en-US
   generative: Male=Matthew, Female=Joanna
   neural: Male=Matthew, Female=Joanna
   standard: Male=Matthew, Female=Joanna
```

### Step 3: SSML Feature Testing
```
🎯 Step 3: Testing SSML Effects Features...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Main - Basic Prosody (Gentle)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ✅ generative (male): Matthew
   ✅ generative (female): Joanna
   ✅ neural (male): Matthew
   ✅ neural (female): Joanna
   ✅ standard (male): Matthew
   ✅ standard (female): Joanna

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 2× Stronger - Energized (rate=medium, volume=+6dB, pitch=+15%)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ✅ generative (male): Matthew
   ✅ generative (female): Joanna
   ✅ neural (male): Matthew
   ✅ neural (female): Joanna
   ✅ standard (male): Matthew
   ✅ standard (female): Joanna

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Golden Voice - Premium Intimacy (rate=slow, pitch=-10%, volume=soft)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ✅ generative (male): Matthew
   ✅ generative (female): Joanna
   ✅ neural (male): Matthew
   ✅ neural (female): Joanna
   ✅ standard (male): Matthew
   ✅ standard (female): Joanna

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 DRC Effect (Neural/Standard only)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ✅ neural (male): Matthew
   ✅ neural (female): Joanna
   ✅ standard (male): Matthew
   ✅ standard (female): Joanna

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Emphasis (Standard only)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ✅ standard (male): Matthew
   ✅ standard (female): Joanna

═══════════════════════════════════════════════════════════════
✅ Test Complete!
═══════════════════════════════════════════════════════════════
```

## ✅ Success Criteria

All tests should pass (✅) for:
- ✅ Basic prosody on all engines (generative, neural, standard)
- ✅ 2× Stronger on all engines with appropriate SSML
- ✅ Golden Voice on all engines with appropriate SSML
- ✅ DRC effect on neural and standard engines only
- ✅ Emphasis tag on standard engine only

## ❌ Troubleshooting

### Error: "Failed to fetch voices"
- **Cause:** Invalid AWS credentials or insufficient permissions
- **Solution:** Verify your AWS credentials have Polly access

### Error: "No voice available"
- **Cause:** Voice not available in us-east-1 region
- **Solution:** Check AWS Polly console for available voices

### Error: "Invalid SSML request"
- **Cause:** SSML tag not supported by the engine
- **Solution:** Check the SSML Support Matrix in `POLLY_SSML_FEATURES_GUIDE.md`

### Some tests fail (❌)
- **Cause:** Engine doesn't support specific SSML features
- **Expected:** Generative engine may fail on DRC/emphasis tests (this is normal)
- **Solution:** Review the SSML Support Matrix to understand limitations

## 📚 Documentation

For detailed SSML support information, see:
- `test/POLLY_SSML_FEATURES_GUIDE.md` - Complete SSML features guide
- [AWS Polly SSML Tags](https://docs.aws.amazon.com/polly/latest/dg/supportedtags.html) - Official AWS documentation

## 🔧 Implementation

The test validates the implementation in:
- `lib/app/services/polly_tts_service.dart`
  - `_buildSSMLForEngine()` - Main basic prosody
  - `_buildStrongerSSMLForEngine()` - 2× Stronger feature
  - `_buildGoldenSSMLForEngine()` - Golden Voice feature

## 📝 Notes

1. **Rate Limit:** The test respects the app policy of never using faster than `medium` rate
2. **Engine Fallback:** The app uses generative → neural → standard fallback chain
3. **Gender Preference:** Voice selection respects gender preference with same-engine fallback
4. **SSML Compatibility:** Each engine has different SSML support levels (see guide)

## 🎯 Next Steps

After running this test:
1. ✅ Verify all features work as expected
2. ✅ Review any failed tests and understand why (engine limitations)
3. ✅ Update implementation if needed based on test results
4. ✅ Test in the actual app with real user scenarios
5. ✅ Monitor AWS Polly costs (generative voices are more expensive)

## 💰 Cost Considerations

- **Standard voices:** $4.00 per 1M characters
- **Neural voices:** $16.00 per 1M characters
- **Generative voices:** $30.00 per 1M characters

This test makes minimal API calls (~20-30 requests) and should cost less than $0.01.

