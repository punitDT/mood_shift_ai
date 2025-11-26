# AWS Polly Voice Limitations

## ⚠️ Languages Without Male Voices

AWS Polly does **NOT** provide male voices for all languages. The following languages in the MoodShift AI app only have **female voices** available:

### 1. **Hindi (hi-IN)** - NO MALE VOICES ❌
**Available voices:**
- **Aditi** - Female (Standard engine only)
- **Kajal** - Female (Neural engine only)

**Impact:**
- When user selects "male" voice for Hindi, the app will use a **female voice** (Aditi or Kajal)
- A warning is logged: `⚠️ [POLLY] Hindi does not have male voices in AWS Polly. Using female voice: [voice_name]`

**User Experience:**
- Users who select male Hindi voice will hear a female voice
- This is a limitation of AWS Polly, not the app

---

## ✅ Languages With Both Male and Female Voices

The following languages have both male and female voices available:

### English (US) - en-US ✅
- **Male**: Joey, Matthew, Justin, Kevin, Gregory, Stephen, Patrick
- **Female**: Joanna, Kendra, Kimberly, Salli, Ivy, Danielle, Ruth

### English (UK) - en-GB ✅
- **Male**: Brian, Arthur
- **Female**: Amy, Emma

### Spanish (Spain) - es-ES ✅
- **Male**: Enrique, Sergio, Raúl
- **Female**: Conchita, Lucia, Alba

### French (France) - fr-FR ✅
- **Male**: Mathieu, Rémi
- **Female**: Céline, Léa

### German (Germany) - de-DE ✅
- **Male**: Hans, Daniel
- **Female**: Marlene, Vicki

### Japanese (Japan) - ja-JP ✅
- **Male**: Takumi
- **Female**: Mizuki, Kazuha, Tomoko

### Chinese Mandarin (China) - cmn-CN ❌ (Female only)
- **Female**: Zhiyu (Neural and Standard)
- **Male**: NOT AVAILABLE

### Arabic (Modern Standard) - arb ❌ (Female only)
- **Female**: Zeina (Standard only)
- **Male**: NOT AVAILABLE

**Note**: Arabic Gulf (ar-AE) has both male (Zayd) and female (Hala) voices, but the app uses Modern Standard Arabic (arb) which only has Zeina (female).

---

## 🔧 Technical Implementation

### Voice Selection Logic
The app uses the following fallback logic in `polly_tts_service.dart`:

1. **Try Neural engine first** (if `_pollyEngine == 'neural'`)
2. **Fallback to Standard engine** if Neural not available
3. **Fallback to en-US** if language not available (Matthew for male, Joanna for female)

### Warning System
When a male voice is requested for Hindi, the app logs:
```dart
if (gender == 'male' && fullLocale == 'hi-IN') {
  print('⚠️ [POLLY] Hindi does not have male voices in AWS Polly. Using female voice: $voiceId');
}
```

---

## 📊 Summary Table

| Language | Language Code | Male Voice | Female Voice | Notes |
|----------|---------------|------------|--------------|-------|
| English (US) | en-US | ✅ Joey, Matthew, etc. | ✅ Joanna, Kendra, etc. | Full support |
| English (UK) | en-GB | ✅ Brian, Arthur | ✅ Amy, Emma | Full support |
| Hindi | hi-IN | ❌ **NOT AVAILABLE** | ✅ Aditi, Kajal | **Uses female voice for male** |
| Spanish (Spain) | es-ES | ✅ Enrique, Sergio, Raúl | ✅ Conchita, Lucia, Alba | Full support |
| Chinese Mandarin | cmn-CN | ❌ **NOT AVAILABLE** | ✅ Zhiyu | **Uses female voice for male** |
| French | fr-FR | ✅ Mathieu, Rémi | ✅ Céline, Léa | Full support |
| German | de-DE | ✅ Hans, Daniel | ✅ Marlene, Vicki | Full support |
| Arabic | arb | ❌ **NOT AVAILABLE** | ✅ Zeina | **Uses female voice for male** |
| Japanese | ja-JP | ✅ Takumi | ✅ Mizuki, Kazuha, Tomoko | Full support |

---

## 🎯 Recommendations

### Option 1: Keep Current Behavior (Recommended)
- Use female voice as fallback when male voice is not available
- Log warning message for debugging
- **Pros**: Simple, works for all languages
- **Cons**: User may be surprised to hear female voice when they selected male

### Option 2: Disable Male Option for Affected Languages
- Hide or disable "male" voice option in settings for Hindi, Chinese, and Arabic
- **Pros**: Clear user expectation
- **Cons**: Requires UI changes, may confuse users

### Option 3: Show Warning to User
- Display a message in the app: "Male voice not available for Hindi. Using female voice."
- **Pros**: Transparent to user
- **Cons**: May interrupt user experience

### Option 4: Use Alternative Language Variant
- For Arabic: Use Arabic Gulf (ar-AE) which has male voice (Zayd)
- **Pros**: Provides male voice option
- **Cons**: Different dialect, may not be preferred by users

---

## 🔍 Current Status

**Implementation**: Option 1 (Keep Current Behavior)
- ✅ Female voice used as fallback for male selection
- ✅ Warning logged to console for debugging
- ✅ No UI changes required
- ✅ Works seamlessly for all languages

**User Impact**:
- Users selecting male voice for Hindi, Chinese, or Arabic will hear a female voice
- This is clearly logged in the console for debugging purposes
- No error or crash occurs

---

## 📚 References

- [AWS Polly Available Voices](https://docs.aws.amazon.com/polly/latest/dg/available-voices.html)
- Last updated: 2025-11-24
- Source: AWS Polly Developer Guide

---

**Note**: This is a limitation of AWS Polly service, not the MoodShift AI app. AWS may add male voices for these languages in the future.

