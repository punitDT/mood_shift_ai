# AWS Polly SSML Quick Reference

## 🎯 Engine Support Matrix

| Feature | Generative | Neural | Standard |
|---------|-----------|--------|----------|
| **Basic Prosody** | ✅ Word values only | ✅ Word + % | ✅ Full |
| **DRC** | ❌ | ✅ | ✅ |
| **Emphasis** | ❌ | ❌ | ✅ |
| **Phonation** | ❌ | ❌ | ✅ |
| **Vocal Tract** | ❌ | ❌ | ✅ |

## 📝 SSML Templates

### Main - Basic Prosody

#### Generative Engine
```xml
<speak>
  <prosody rate="slow|medium" volume="x-soft|soft|medium|loud|x-loud">
    Your text here
  </prosody>
</speak>
```

#### Neural/Standard Engine
```xml
<speak>
  <prosody rate="slow|medium" volume="soft|medium|loud" pitch="low|medium|high">
    Your text here
  </prosody>
</speak>
```

---

### 2× Stronger - Energized

#### Generative Engine
```xml
<speak>
  <prosody rate="medium" volume="x-loud">
    Your text here
  </prosody>
</speak>
```

#### Neural Engine
```xml
<speak>
  <prosody rate="medium" volume="+6dB" pitch="+15%">
    Your text here
  </prosody>
</speak>
```

#### Standard Engine (Full)
```xml
<speak>
  <emphasis level="strong">
    <prosody rate="medium" volume="+6dB" pitch="+15%">
      Your text here
    </prosody>
  </emphasis>
</speak>
```

---

### Golden Voice - Premium Intimacy

#### Generative Engine
```xml
<speak>
  <prosody rate="x-slow" volume="x-soft">
    Your text here
  </prosody>
</speak>
```

#### Neural Engine
```xml
<speak>
  <amazon:effect name="drc">
    <prosody rate="slow" pitch="-10%" volume="soft">
      Your text here
    </prosody>
  </amazon:effect>
</speak>
```

#### Standard Engine (Full)
```xml
<speak>
  <amazon:effect name="drc">
    <amazon:effect phonation="soft">
      <amazon:effect vocal-tract-length="+12%">
        <prosody rate="slow" pitch="-10%" volume="soft">
          Your text here
        </prosody>
      </amazon:effect>
    </amazon:effect>
  </amazon:effect>
</speak>
```

---

## 🎨 Mood Style Prosody Settings

### Gentle Grandma
```xml
<prosody rate="slow" volume="soft" pitch="low">
```

### Chaos Energy
```xml
<prosody rate="medium" volume="loud" pitch="high">
```

### Permission Slip
```xml
<prosody rate="medium" volume="medium" pitch="medium">
```

### Reality Check
```xml
<prosody rate="medium" volume="medium" pitch="medium">
```

### Micro Dare
```xml
<prosody rate="medium" volume="medium" pitch="medium">
```

---

## 📊 Prosody Attribute Values

### Rate (Speed)
| Value | Generative | Neural | Standard | Notes |
|-------|-----------|--------|----------|-------|
| `x-slow` | ✅ | ✅ | ✅ | Very slow |
| `slow` | ✅ | ✅ | ✅ | Slow |
| `medium` | ✅ | ✅ | ✅ | Default |
| `fast` | ❌ Never use | ❌ Never use | ❌ Never use | **App policy: max medium** |
| `x-fast` | ❌ Never use | ❌ Never use | ❌ Never use | **App policy: max medium** |
| `+20%` | ❌ | ⚠️ Partial | ✅ | Percentage increase |
| `-20%` | ❌ | ⚠️ Partial | ✅ | Percentage decrease |

### Volume (Loudness)
| Value | Generative | Neural | Standard | Notes |
|-------|-----------|--------|----------|-------|
| `silent` | ✅ | ✅ | ✅ | Silent |
| `x-soft` | ✅ | ✅ | ✅ | Very soft |
| `soft` | ✅ | ✅ | ✅ | Soft |
| `medium` | ✅ | ✅ | ✅ | Default |
| `loud` | ✅ | ✅ | ✅ | Loud |
| `x-loud` | ✅ | ✅ | ✅ | Very loud |
| `+6dB` | ⚠️ Partial | ✅ | ✅ | Decibel increase |
| `-6dB` | ⚠️ Partial | ✅ | ✅ | Decibel decrease |

### Pitch (Tone)
| Value | Generative | Neural | Standard | Notes |
|-------|-----------|--------|----------|-------|
| `x-low` | ❌ Unreliable | ⚠️ Partial | ✅ | Very low |
| `low` | ❌ Unreliable | ⚠️ Partial | ✅ | Low |
| `medium` | ❌ Unreliable | ⚠️ Partial | ✅ | Default |
| `high` | ❌ Unreliable | ⚠️ Partial | ✅ | High |
| `x-high` | ❌ Unreliable | ⚠️ Partial | ✅ | Very high |
| `+15%` | ❌ | ✅ | ✅ | Percentage increase |
| `-10%` | ❌ | ✅ | ✅ | Percentage decrease |

---

## 🔧 Amazon Effect Tags

### DRC (Dynamic Range Compression)
```xml
<amazon:effect name="drc">
  Your text here
</amazon:effect>
```
- ❌ Generative: Not supported
- ✅ Neural: Supported
- ✅ Standard: Supported

### Phonation (Soft Voice)
```xml
<amazon:effect phonation="soft">
  Your text here
</amazon:effect>
```
- ❌ Generative: Not supported
- ❌ Neural: Not supported
- ✅ Standard: Supported

### Vocal Tract Length (Timbre)
```xml
<amazon:effect vocal-tract-length="+12%">
  Your text here
</amazon:effect>
```
- ❌ Generative: Not supported
- ❌ Neural: Not supported
- ✅ Standard: Supported

### Emphasis (Stress)
```xml
<emphasis level="strong">
  Your text here
</emphasis>
```
- ❌ Generative: Not supported
- ❌ Neural: Not supported
- ✅ Standard: Supported

---

## 🌍 Available Voices (us-east-1)

### Generative Voices (en-US)
- **Male:** Matthew, Stephen
- **Female:** Danielle, Joanna, Ruth, Salli

### Neural Voices (en-US)
- **Male:** Matthew, Joey, Justin, Kevin
- **Female:** Joanna, Ivy, Kendra, Kimberly, Salli

### Standard Voices (en-US)
- **Male:** Matthew, Joey, Justin
- **Female:** Joanna, Ivy, Kendra, Kimberly, Salli

---

## ⚠️ Important Notes

1. **Never use faster than `medium` rate** - App policy
2. **Generative voices are most expensive** - $30/1M chars
3. **Fallback chain:** Generative → Neural → Standard
4. **Gender preference:** Try same gender across engines before switching
5. **SSML validation:** Always escape XML special characters

---

## 🧪 Testing

Run the comprehensive test:
```bash
dart test/test_polly_ssml_features.dart <AWS_ACCESS_KEY> <AWS_SECRET_KEY>
```

See `test/README_SSML_TEST.md` for detailed instructions.

---

## 📚 References

- [AWS Polly SSML Tags](https://docs.aws.amazon.com/polly/latest/dg/supportedtags.html)
- [Generative Voices](https://docs.aws.amazon.com/polly/latest/dg/generative-voices.html)
- [Neural Voices](https://docs.aws.amazon.com/polly/latest/dg/neural-voices.html)
- [Prosody Tag](https://docs.aws.amazon.com/polly/latest/dg/prosody-tag.html)

---

**Last Updated:** 2025-11-26  
**Region:** us-east-1  
**App:** MoodShift AI

