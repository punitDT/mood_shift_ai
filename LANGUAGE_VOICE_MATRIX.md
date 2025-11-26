# Language & Voice Support Matrix

**MoodShift AI - AWS Polly Integration**  
**Date:** 2025-11-26  
**Region:** us-east-1

---

## 🌍 Complete Language Support Matrix

### English (US) - en-US 🇺🇸

| Engine | Male Voice | Female Voice | SSML Support |
|--------|------------|--------------|--------------|
| **Generative** | Matthew | Danielle | x-values only |
| **Neural** | Gregory | Danielle | Volume (dB) + DRC |
| **Standard** | Matthew | Joanna | Full SSML |

**Test Phrase:** "Hello, this is a test of the SSML features."

---

### English (UK) - en-GB 🇬🇧

| Engine | Male Voice | Female Voice | SSML Support |
|--------|------------|--------------|--------------|
| **Generative** | ❌ None | Amy | x-values only |
| **Neural** | Brian | Emma | Volume (dB) + DRC |
| **Standard** | Brian | Emma | Full SSML |

**Test Phrase:** "Hello, this is a test of the SSML features."

**Note:** No male generative voice available. Falls back to female or neural engine.

---

### Spanish (Spain) - es-ES 🇪🇸

| Engine | Male Voice | Female Voice | SSML Support |
|--------|------------|--------------|--------------|
| **Generative** | Sergio | Lucia | x-values only |
| **Neural** | Sergio | Lucia | Volume (dB) + DRC |
| **Standard** | Enrique | Lucia | Full SSML |

**Test Phrase:** "Hola, esta es una prueba de las funciones SSML."

---

### French (France) - fr-FR 🇫🇷

| Engine | Male Voice | Female Voice | SSML Support |
|--------|------------|--------------|--------------|
| **Generative** | Remi | Lea | x-values only |
| **Neural** | Remi | Lea | Volume (dB) + DRC |
| **Standard** | Mathieu | Lea | Full SSML |

**Test Phrase:** "Bonjour, ceci est un test des fonctionnalités SSML."

---

### German (Germany) - de-DE 🇩🇪

| Engine | Male Voice | Female Voice | SSML Support |
|--------|------------|--------------|--------------|
| **Generative** | Daniel | Vicki | x-values only |
| **Neural** | Daniel | Vicki | Volume (dB) + DRC |
| **Standard** | Hans | Vicki | Full SSML |

**Test Phrase:** "Hallo, dies ist ein Test der SSML-Funktionen."

---

### Hindi (India) - hi-IN 🇮🇳

| Engine | Male Voice | Female Voice | SSML Support |
|--------|------------|--------------|--------------|
| **Generative** | ❌ None | Kajal | x-values only |
| **Neural** | ❌ None | Kajal | Volume (dB) + DRC |
| **Standard** | ❌ None | Aditi | Full SSML |

**Test Phrase:** "नमस्ते, यह SSML सुविधाओं का परीक्षण है।"

**Note:** Only female voices available for Hindi. No male voices across all engines.

---

### Chinese (Mandarin) - cmn-CN 🇨🇳

| Engine | Male Voice | Female Voice | SSML Support |
|--------|------------|--------------|--------------|
| **Generative** | ❌ None | ❌ None | N/A |
| **Neural** | ❌ None | Zhiyu | Volume (dB) + DRC |
| **Standard** | ❌ None | Zhiyu | Full SSML |

**Test Phrase:** "你好，这是SSML功能的测试。"

**Note:** No generative voices available. Neural and Standard only. Female voice only.

---

### Arabic - arb 🇸🇦

| Engine | Male Voice | Female Voice | SSML Support |
|--------|------------|--------------|--------------|
| **Generative** | ❌ None | ❌ None | N/A |
| **Neural** | ❌ None | ❌ None | N/A |
| **Standard** | ❌ None | Zeina | Full SSML |

**Test Phrase:** "مرحبا، هذا اختبار لميزات SSML."

**Note:** Standard engine only. Female voice only. Most limited language support.

---

### Japanese - ja-JP 🇯🇵

| Engine | Male Voice | Female Voice | SSML Support |
|--------|------------|--------------|--------------|
| **Generative** | ❌ None | ❌ None | N/A |
| **Neural** | Takumi | Kazuha | Volume (dB) + DRC |
| **Standard** | Takumi | Mizuki | Full SSML |

**Test Phrase:** "こんにちは、これはSSML機能のテストです。"

**Note:** No generative voices available. Neural and Standard only.

---

## 📊 Summary Statistics

### Language Coverage
- **Total Languages:** 9
- **Full Support (3 engines):** 6 languages
- **Partial Support (2 engines):** 2 languages (Chinese, Japanese)
- **Limited Support (1 engine):** 1 language (Arabic)

### Voice Coverage
- **Total Voices:** 103 across all languages
- **Generative Voices:** Available in 6 languages
- **Neural Voices:** Available in 8 languages
- **Standard Voices:** Available in all 9 languages

### Gender Coverage
- **Both Genders:** en-US, es-ES, fr-FR, de-DE, ja-JP
- **Female Only:** en-GB (generative), hi-IN, cmn-CN, arb
- **Male Generative Missing:** en-GB, hi-IN

---

## 🎯 SSML Feature Support by Language

### All 3 Features Supported (Main, 2× Stronger, Golden Voice)

| Language | Generative | Neural | Standard |
|----------|-----------|--------|----------|
| en-US 🇺🇸 | ✅ Full | ✅ Full | ✅ Full |
| en-GB 🇬🇧 | ✅ Female only | ✅ Full | ✅ Full |
| es-ES 🇪🇸 | ✅ Full | ✅ Full | ✅ Full |
| fr-FR 🇫🇷 | ✅ Full | ✅ Full | ✅ Full |
| de-DE 🇩🇪 | ✅ Full | ✅ Full | ✅ Full |
| hi-IN 🇮🇳 | ✅ Female only | ✅ Female only | ✅ Female only |
| cmn-CN 🇨🇳 | ❌ None | ✅ Female only | ✅ Female only |
| arb 🇸🇦 | ❌ None | ❌ None | ✅ Female only |
| ja-JP 🇯🇵 | ❌ None | ✅ Full | ✅ Full |

---

## 💡 Implementation Guidelines

### Fallback Strategy

1. **Engine Fallback:** Generative → Neural → Standard
2. **Gender Fallback:** Preferred gender → Available gender
3. **Language Fallback:** Requested language → English (en-US)

### Example Fallback Scenarios

#### Scenario 1: Hindi Male Voice
```
Request: hi-IN, male, generative
Fallback: hi-IN, female, generative (Kajal)
Reason: No male voices available in Hindi
```

#### Scenario 2: Chinese Generative
```
Request: cmn-CN, female, generative
Fallback: cmn-CN, female, neural (Zhiyu)
Reason: No generative voices for Chinese
```

#### Scenario 3: Arabic Neural
```
Request: arb, female, neural
Fallback: arb, female, standard (Zeina)
Reason: No neural voices for Arabic
```

---

## 🔧 Code Usage

### Get Voice for Language
```dart
final voiceId = _getPollyVoice('es-ES');  // Returns: Sergio or Lucia
```

### Get Language-Specific Test Phrase
```dart
final testPhrase = getTestPhrase('fr-FR');  // Returns: "Bonjour, ceci est..."
```

### Build SSML for Language
```dart
final ssml = _buildSSMLForEngine(
  text: 'Hola mundo',
  engine: 'generative',
  prosody: {'rate': 'slow', 'volume': 'soft'},
);
// Returns: <speak><prosody rate="x-slow" volume="x-soft">Hola mundo</prosody></speak>
```

---

## 🧪 Testing

### Run Tests for All Languages
```bash
./test/RUN_TEST.sh
```

### Run Tests for Specific Language
```bash
# Modify test file to filter by language
dart test/test_polly_ssml_features.dart $AWS_KEY $AWS_SECRET
```

### Expected Test Count by Language
- **en-US, en-GB, es-ES, fr-FR, de-DE, hi-IN:** 14 tests each
- **cmn-CN, ja-JP:** 10 tests each (no generative)
- **arb:** 6 tests (standard only)

---

## 📝 Notes

### Character Encoding
- All languages use UTF-8 encoding
- Special characters properly handled in SSML
- Right-to-left languages (Arabic) supported

### Voice Quality
- **Generative:** Highest quality, most natural
- **Neural:** High quality, good balance
- **Standard:** Good quality, most features

### Cost Optimization
- **Generative:** $30/1M chars - Use for premium features
- **Neural:** $16/1M chars - Good balance
- **Standard:** $4/1M chars - Most cost-effective

---

## 🎉 Quick Reference

| Need | Use This |
|------|----------|
| Best quality | Generative (if available) |
| Best features | Standard |
| Best balance | Neural |
| Lowest cost | Standard |
| Most languages | Standard (all 9) |
| Newest tech | Generative (6 languages) |

---

**Last Updated:** 2025-11-26  
**Version:** 2.0.0  
**Status:** ✅ Production Ready

