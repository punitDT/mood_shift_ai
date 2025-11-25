# AWS Polly Voice Test Results

**Date:** November 25, 2025  
**Region:** us-east-1  
**Test Script:** `test/polly_voice_test.dart`

## Executive Summary

Comprehensive testing of all AWS Polly voices across 15 languages revealed critical incompatibilities between certain voices and engine types. The key finding: **many "generative" voices do NOT support the "standard" engine**, causing fallback failures.

## Critical Issues Fixed

### 1. **Danielle (en-US Female)** ❌
- **Problem:** Does NOT support "standard" engine
- **Solution:** Use "Joanna" for standard engine fallback
- **Impact:** This was causing the error you saw!

### 2. **Kajal (hi-IN)** ❌
- **Problem:** Does NOT support "standard" engine
- **Solution:** Use "Aditi" for standard engine fallback

### 3. **Sergio (es-ES Male)** ❌
- **Problem:** Does NOT support "standard" engine
- **Solution:** Use "Enrique" for standard engine fallback

### 4. **Remi (fr-FR Male)** ❌
- **Problem:** Does NOT support "standard" engine
- **Solution:** Use "Mathieu" for standard engine fallback

### 5. **Daniel (de-DE Male)** ❌
- **Problem:** Does NOT support "standard" engine
- **Solution:** Use "Hans" for standard engine fallback

## Complete Test Results by Language

### 🇺🇸 English (US) - en-US

| Voice | Gender | Generative | Neural | Standard |
|-------|--------|------------|--------|----------|
| Matthew | Male | ✅ | ✅ | ✅ |
| Stephen | Male | ✅ | ✅ | ❌ |
| Joey | Male | ❌ | ✅ | ✅ |
| Justin | Male | ❌ | ✅ | ✅ |
| Kevin | Male | ❌ | ✅ | ❌ |
| Danielle | Female | ✅ | ✅ | ❌ |
| Joanna | Female | ✅ | ✅ | ✅ |
| Salli | Female | ✅ | ✅ | ✅ |
| Ruth | Female | ✅ | ✅ | ❌ |
| Kendra | Female | ❌ | ✅ | ✅ |
| Kimberly | Female | ❌ | ✅ | ✅ |
| Ivy | Female | ❌ | ✅ | ✅ |

**Recommended:**
- Generative: Matthew (M), Danielle (F)
- Neural: Matthew (M), Danielle (F)
- Standard: Matthew (M), Joanna (F) ⚠️

### 🇬🇧 English (UK) - en-GB

| Voice | Gender | Generative | Neural | Standard |
|-------|--------|------------|--------|----------|
| Brian | Male | ❌ | ✅ | ✅ |
| Arthur | Male | ❌ | ✅ | ❌ |
| Amy | Female | ✅ | ✅ | ✅ |
| Emma | Female | ❌ | ✅ | ✅ |

**Recommended:**
- Generative: Amy (F only)
- Neural: Brian (M), Amy (F)
- Standard: Brian (M), Amy (F)

### 🇮🇳 Hindi - hi-IN

| Voice | Gender | Generative | Neural | Standard |
|-------|--------|------------|--------|----------|
| Kajal | Both | ✅ | ✅ | ❌ |
| Aditi | Female | ❌ | ❌ | ✅ |

**Recommended:**
- Generative: Kajal (no male voice)
- Neural: Kajal (no male voice)
- Standard: Aditi (no male voice) ⚠️

### 🇪🇸 Spanish (Spain) - es-ES

| Voice | Gender | Generative | Neural | Standard |
|-------|--------|------------|--------|----------|
| Sergio | Male | ✅ | ✅ | ❌ |
| Enrique | Male | ❌ | ❌ | ✅ |
| Lucia | Female | ✅ | ✅ | ✅ |
| Conchita | Female | ❌ | ❌ | ✅ |

**Recommended:**
- Generative: Sergio (M), Lucia (F)
- Neural: Sergio (M), Lucia (F)
- Standard: Enrique (M), Lucia (F) ⚠️

### 🇲🇽 Spanish (Mexico) - es-MX

| Voice | Gender | Generative | Neural | Standard |
|-------|--------|------------|--------|----------|
| Andres | Male | ✅ | ✅ | ❌ |
| Mia | Female | ✅ | ✅ | ✅ |

**Recommended:**
- Generative: Andres (M), Mia (F)
- Neural: Andres (M), Mia (F)
- Standard: Mia (F only)

### 🇫🇷 French (France) - fr-FR

| Voice | Gender | Generative | Neural | Standard |
|-------|--------|------------|--------|----------|
| Remi | Male | ✅ | ✅ | ❌ |
| Mathieu | Male | ❌ | ❌ | ✅ |
| Lea | Female | ✅ | ✅ | ✅ |
| Celine | Female | ✅ | ❌ | ✅ |

**Recommended:**
- Generative: Remi (M), Lea (F)
- Neural: Remi (M), Lea (F)
- Standard: Mathieu (M), Lea (F) ⚠️

### 🇨🇦 French (Canada) - fr-CA

| Voice | Gender | Generative | Neural | Standard |
|-------|--------|------------|--------|----------|
| Liam | Male | ✅ | ✅ | ❌ |
| Gabrielle | Female | ✅ | ✅ | ❌ |
| Chantal | Female | ❌ | ❌ | ✅ |

**Recommended:**
- Generative: Liam (M), Gabrielle (F)
- Neural: Liam (M), Gabrielle (F)
- Standard: Chantal (F only)

### 🇩🇪 German - de-DE

| Voice | Gender | Generative | Neural | Standard |
|-------|--------|------------|--------|----------|
| Daniel | Male | ✅ | ✅ | ❌ |
| Hans | Male | ❌ | ❌ | ✅ |
| Vicki | Female | ✅ | ✅ | ✅ |
| Marlene | Female | ❌ | ❌ | ✅ |

**Recommended:**
- Generative: Daniel (M), Vicki (F)
- Neural: Daniel (M), Vicki (F)
- Standard: Hans (M), Vicki (F) ⚠️

### 🇮🇹 Italian - it-IT

| Voice | Gender | Generative | Neural | Standard |
|-------|--------|------------|--------|----------|
| Adriano | Male | ❌ | ✅ | ❌ |
| Giorgio | Male | ❌ | ❌ | ✅ |
| Bianca | Female | ✅ | ✅ | ✅ |
| Carla | Female | ❌ | ❌ | ✅ |

**Recommended:**
- Generative: Bianca (F only)
- Neural: Adriano (M), Bianca (F)
- Standard: Giorgio (M), Bianca (F)

### 🇧🇷 Portuguese (Brazil) - pt-BR

| Voice | Gender | Generative | Neural | Standard |
|-------|--------|------------|--------|----------|
| Thiago | Male | ❌ | ✅ | ❌ |
| Camila | Female | ✅ | ✅ | ✅ |
| Vitoria | Female | ❌ | ✅ | ✅ |

**Recommended:**
- Generative: Camila (F only)
- Neural: Thiago (M), Camila (F)
- Standard: Camila (F only)

### 🇯🇵 Japanese - ja-JP

| Voice | Gender | Generative | Neural | Standard |
|-------|--------|------------|--------|----------|
| Takumi | Male | ❌ | ✅ | ✅ |
| Kazuha | Female | ❌ | ✅ | ❌ |
| Mizuki | Female | ❌ | ❌ | ✅ |

**Recommended:**
- Generative: ❌ None available (fallback to neural)
- Neural: Takumi (M), Kazuha (F)
- Standard: Takumi (M), Mizuki (F)

### 🇰🇷 Korean - ko-KR

| Voice | Gender | Generative | Neural | Standard |
|-------|--------|------------|--------|----------|
| Seoyeon | Both | ✅ | ✅ | ✅ |

**Recommended:**
- Generative: Seoyeon (no male voice)
- Neural: Seoyeon (no male voice)
- Standard: Seoyeon (no male voice)

### 🇨🇳 Chinese (Mandarin) - cmn-CN

| Voice | Gender | Generative | Neural | Standard |
|-------|--------|------------|--------|----------|
| Zhiyu | Both | ❌ | ✅ | ✅ |

**Recommended:**
- Generative: ❌ None available (fallback to neural)
- Neural: Zhiyu (no male voice)
- Standard: Zhiyu (no male voice)

### 🇸🇦 Arabic (Standard) - arb

| Voice | Gender | Generative | Neural | Standard |
|-------|--------|------------|--------|----------|
| Zeina | Both | ❌ | ❌ | ✅ |

**Recommended:**
- Generative: ❌ None available (fallback to standard)
- Neural: ❌ None available (fallback to standard)
- Standard: Zeina (no male voice)

### 🇦🇪 Arabic (UAE) - ar-AE

| Voice | Gender | Generative | Neural | Standard |
|-------|--------|------------|--------|----------|
| Hala | Both | ❌ | ✅ | ❌ |

**Recommended:**
- Generative: ❌ None available (fallback to neural)
- Neural: Hala (no male voice)
- Standard: ❌ None available (fallback to neural)

## Key Insights

### Languages with Full Generative Support
✅ **en-US, en-GB, hi-IN, es-ES, es-MX, fr-FR, fr-CA, de-DE, it-IT, pt-BR, ko-KR**

### Languages WITHOUT Generative Support
❌ **ja-JP, cmn-CN, arb, ar-AE** (will auto-fallback to neural/standard)

### Voices That Don't Support Standard Engine
⚠️ Many generative voices don't support standard:
- Danielle, Stephen, Ruth (en-US)
- Kajal (hi-IN)
- Sergio (es-ES)
- Andres (es-MX)
- Remi (fr-FR)
- Liam, Gabrielle (fr-CA)
- Daniel (de-DE)
- And many more...

## Implementation Changes

The voice mappings in `lib/app/services/polly_tts_service.dart` have been updated to:

1. ✅ Use tested and verified voices for each engine
2. ✅ Provide proper fallback voices for standard engine
3. ✅ Add clear comments indicating which voices support which engines
4. ✅ Ensure smooth degradation: Generative → Neural → Standard → flutter_tts

## Testing

Run the test again anytime to verify:
```bash
flutter test test/polly_voice_test.dart
```

This will test all voices and generate updated mappings if AWS adds new voices.

