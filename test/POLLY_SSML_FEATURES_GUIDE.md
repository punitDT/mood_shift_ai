# AWS Polly SSML Features Guide

## 📋 Overview

This guide documents the SSML (Speech Synthesis Markup Language) features supported by AWS Polly across different voice engines (Generative, Neural, Standard) for the MoodShift AI application.

**Last Updated:** 2025-11-26  
**AWS Region:** us-east-1  
**Documentation Source:** [AWS Polly SSML Tags](https://docs.aws.amazon.com/polly/latest/dg/supportedtags.html)

---

## 🎯 SSML Support Matrix

### Complete Tag Support by Engine

**⚠️ TESTED WITH REAL AWS API (2025-11-26)**

| SSML Tag/Feature | Generative | Neural | Standard | Notes |
|-----------------|------------|--------|----------|-------|
| `<speak>` | ✅ Full | ✅ Full | ✅ Full | Required wrapper |
| `<prosody>` | ⚠️ x-values only | ⚠️ volume (dB) only | ✅ Full | See details below |
| `<break>` | ✅ Full | ✅ Full | ✅ Full | Pause control |
| `<lang>` | ✅ Full | ✅ Full | ✅ Full | Language switching |
| `<p>` / `<s>` | ✅ Full | ✅ Full | ✅ Full | Paragraph/sentence |
| `<say-as>` | ✅ Full | ⚠️ Partial | ✅ Full | Number formatting |
| `<sub>` | ✅ Full | ✅ Full | ✅ Full | Substitution |
| `<w>` | ✅ Full | ✅ Full | ✅ Full | Word-level control |
| `<emphasis>` | ❌ Not available | ❌ Not available | ✅ Full | Standard only |
| `<amazon:effect name="drc">` | ❌ Not available | ✅ Full | ✅ Full | Dynamic range compression |
| `<amazon:effect phonation>` | ❌ Not available | ❌ Not available | ✅ Full | Standard only |
| `<amazon:effect vocal-tract-length>` | ❌ Not available | ❌ Not available | ✅ Full | Standard only |
| `<amazon:effect name="whispered">` | ❌ Not available | ❌ Not available | ❌ Not available | Not supported |
| `<amazon:auto-breaths>` | ❌ Not available | ❌ Not available | ❌ Not available | Not supported |
| `<amazon:domain name="news">` | ❌ Not available | ⚠️ Select voices | ❌ Not available | Limited neural support |

---

## 🎵 Prosody Tag Details

### Supported Attributes

The `<prosody>` tag supports three main attributes:

#### 1. **Rate** (Speech Speed)

**⚠️ REAL TEST RESULTS (2025-11-26):**

- **Generative Engine:**
  - ✅ Supports: `x-slow`, `medium` ONLY
  - ❌ Does NOT support: `slow`, `fast`, `x-fast`, percentages
  - **TESTED:** Only x-values work

- **Neural Engine:**
  - ❌ Does NOT support: ANY rate values (word or percentage)
  - **TESTED:** Rate attribute is completely ignored

- **Standard Engine:**
  - ✅ Full support: All word values and percentages

**Recommended Values:**
- Slow: `x-slow` (generative), `slow` (standard)
- Medium: `medium` (all engines)
- Fast: ❌ **Never use** - violates app policy of max medium speed

#### 2. **Volume** (Loudness)

**⚠️ REAL TEST RESULTS (2025-11-26):**

- **Generative Engine:**
  - ✅ Supports: `x-soft`, `medium`, `x-loud` ONLY
  - ❌ Does NOT support: `soft`, `loud`, decibel values
  - **TESTED:** Only x-values work

- **Neural Engine:**
  - ✅ Supports: Decibel values ONLY (`+0dB`, `+6dB`, `-6dB`)
  - ❌ Does NOT support: Word values (`soft`, `loud`, etc.)
  - **TESTED:** Only dB format works

- **Standard Engine:**
  - ✅ Full support: All word values and decibel values

**Recommended Values:**
- Soft: `x-soft` (generative), `-6dB` (neural), `soft` (standard)
- Medium: `medium` (generative), `+0dB` (neural), `medium` (standard)
- Loud: `x-loud` (generative), `+6dB` (neural), `loud` (standard)
- Amplified: `+10dB` (neural/standard only)

#### 3. **Pitch** (Tone)

**⚠️ REAL TEST RESULTS (2025-11-26):**

- **Generative Engine:**
  - ❌ Does NOT support: ANY pitch values
  - **TESTED:** Pitch attribute is completely ignored

- **Neural Engine:**
  - ❌ Does NOT support: ANY pitch values (word or percentage)
  - **TESTED:** Pitch attribute is completely ignored

- **Standard Engine:**
  - ✅ Full support: All word values and percentages

**Recommended Values:**
- Low: `low` or `-10%` (standard only)
- Medium: `medium` (standard only)
- High: `high` or `+15%` (standard only)
- **Note:** Generative and Neural do NOT support pitch control

---

## 🎭 MoodShift AI SSML Features

### Feature 1: Main - Basic Prosody

**Purpose:** Natural, style-appropriate speech modulation

**Implementation:**
```xml
<!-- Gentle Grandma Style -->
<speak>
  <prosody rate="slow" volume="soft" pitch="low">
    Your text here
  </prosody>
</speak>

<!-- Chaos Energy Style -->
<speak>
  <prosody rate="medium" volume="loud" pitch="high">
    Your text here
  </prosody>
</speak>
```

**Engine Compatibility:**
- ✅ Generative: Use word values only (`slow`, `medium`, `loud`, etc.)
- ✅ Neural: Use word values or percentages
- ✅ Standard: Full support

---

### Feature 2: 2× Stronger - Energized Speech

**Purpose:** Amplified, powerful, motivational speech

**Specification:**
- Rate: `medium` (max - never faster per app policy)
- Volume: `+6dB` (amplified)
- Pitch: `+15%` (elevated)
- Optional: `<emphasis level="strong">` (Standard engine only)

**Implementation:**

**For Generative Engine:**
```xml
<speak>
  <prosody rate="medium" volume="x-loud">
    Your text here
  </prosody>
</speak>
```

**For Neural/Standard Engines:**
```xml
<speak>
  <prosody rate="medium" volume="+6dB" pitch="+15%">
    Your text here
  </prosody>
</speak>
```

**For Standard Engine (Enhanced):**
```xml
<speak>
  <emphasis level="strong">
    <prosody rate="medium" volume="+6dB" pitch="+15%">
      Your text here
    </prosody>
  </emphasis>
</speak>
```

**Engine Compatibility:**
- ✅ Generative: Simplified version (word values only)
- ✅ Neural: Full support with decibels and percentages
- ✅ Standard: Full support + emphasis tag

---

### Feature 3: Golden Voice - Premium Intimacy

**Purpose:** Warm, intimate, premium-quality speech

**Specification:**
- Rate: `slow` (deliberate, measured)
- Pitch: `-10%` (warmer, deeper)
- Volume: `soft` (gentle, intimate)
- Optional: `<amazon:effect name="drc">` (Neural/Standard only)

**Implementation:**

**For Generative Engine:**
```xml
<speak>
  <prosody rate="x-slow" volume="x-soft">
    Your text here
  </prosody>
</speak>
```

**For Neural Engine:**
```xml
<speak>
  <amazon:effect name="drc">
    <prosody rate="slow" pitch="-10%" volume="soft">
      Your text here
    </prosody>
  </amazon:effect>
</speak>
```

**For Standard Engine (Full Features):**
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

**Engine Compatibility:**
- ⚠️ Generative: Basic version only (no DRC, phonation, or vocal-tract-length)
- ✅ Neural: DRC supported, no phonation/vocal-tract-length
- ✅ Standard: Full support for all effects

---

## 🧪 Testing

### Running the Test

```bash
# Get your AWS credentials from .env file
dart test/test_polly_ssml_features.dart <AWS_ACCESS_KEY> <AWS_SECRET_KEY>
```

### Expected Output

The test will:
1. ✅ Fetch all available voices from us-east-1
2. ✅ Organize voices by engine (generative > neural > standard) and gender
3. ✅ Test each SSML feature with appropriate voices
4. ✅ Validate compatibility and report results

### Sample Output

```
═══════════════════════════════════════════════════════════════
🧪 AWS Polly SSML Features Test (us-east-1)
═══════════════════════════════════════════════════════════════

📋 Step 1: Fetching available voices from AWS Polly...
✅ Found 87 total voices

📊 Step 2: Organizing voices by engine and gender...
🌍 Language: en-US
   generative: Male=Matthew, Female=Joanna
   neural: Male=Matthew, Female=Joanna
   standard: Male=Matthew, Female=Joanna

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
🎯 2× Stronger - Energized
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ✅ generative (male): Matthew
   ✅ generative (female): Joanna
   ✅ neural (male): Matthew
   ✅ neural (female): Joanna
   ✅ standard (male): Matthew
   ✅ standard (female): Joanna

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Golden Voice - Premium Intimacy
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ✅ generative (male): Matthew
   ✅ generative (female): Joanna
   ✅ neural (male): Matthew
   ✅ neural (female): Joanna
   ✅ standard (male): Matthew
   ✅ standard (female): Joanna

✅ Test Complete!
```

---

## 📝 Implementation Notes

### Current Implementation Status

✅ **Implemented:**
- Basic prosody for all engines
- Engine-specific SSML generation
- Fallback chain: generative → neural → standard
- Gender-based voice selection

⚠️ **Needs Refinement:**
- Golden Voice currently uses simplified SSML
- 2× Stronger doesn't use DRC for neural/standard
- No emphasis tag for standard engine

### Recommended Updates

See `test/test_polly_ssml_features.dart` for validation of these features.

---

## 🔗 References

- [AWS Polly SSML Tags](https://docs.aws.amazon.com/polly/latest/dg/supportedtags.html)
- [Generative Voices](https://docs.aws.amazon.com/polly/latest/dg/generative-voices.html)
- [Neural Voices](https://docs.aws.amazon.com/polly/latest/dg/neural-voices.html)
- [Prosody Tag](https://docs.aws.amazon.com/polly/latest/dg/prosody-tag.html)
- [Amazon Effect Tags](https://docs.aws.amazon.com/polly/latest/dg/supported-ssml.html)

