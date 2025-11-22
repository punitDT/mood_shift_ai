# MoodShift AI - API Integration Guide

## 🤖 Hugging Face LLM Integration

### Overview
MoodShift AI uses the Meta-Llama-3-8B-Instruct model from Hugging Face for generating AI responses.

### Setup Steps

#### 1. Create Hugging Face Account
1. Go to https://huggingface.co/
2. Sign up for a free account
3. Verify your email

#### 2. Generate API Token
1. Go to https://huggingface.co/settings/tokens
2. Click "New token"
3. Name: "MoodShift AI"
4. Type: Read
5. Click "Generate"
6. Copy the token (starts with `hf_`)

#### 3. Add Token to App
Open `lib/app/services/ai_service.dart` and replace line 17:

```dart
static const String _apiToken = 'hf_your_actual_token_here';
```

### API Details

**Endpoint**: `https://api-inference.huggingface.co/models/meta-llama/Meta-Llama-3-8B-Instruct`

**Model**: Meta-Llama-3-8B-Instruct

**Request Format**:
```json
{
  "inputs": "Your prompt here",
  "parameters": {
    "max_new_tokens": 150,
    "temperature": 0.9,
    "top_p": 0.95,
    "do_sample": true
  }
}
```

**Response Format**:
```json
[
  {
    "generated_text": "Full response including prompt and generated text"
  }
]
```

### Prompt Engineering

The app uses carefully crafted prompts with:
- **Safety rules**: Never judge, redirect harmful intent
- **Style instructions**: 5 different mood styles
- **Language support**: Responds in user's selected language
- **Length control**: 10-30 seconds when spoken (50-100 words)

### 5 Mood Styles

1. **Chaos Energy**
   - Hyper, energetic dares
   - Fast-paced, exciting
   - Pushes user to action NOW

2. **Gentle Grandma**
   - Soft, nurturing tone
   - Breathing exercises
   - Calming and soothing

3. **Permission Slip**
   - Formal yet playful
   - Official permission to do/not do something
   - "You are hereby granted permission..."

4. **Reality Check**
   - Kind, honest truth
   - Direct but loving
   - Helps see things clearly

5. **Micro Dare**
   - One tiny, specific action
   - Achievable in 60 seconds
   - Simple and fun

### Fallback Responses

If the API fails, the app uses pre-written fallback responses in all 8 languages to ensure the user always gets a response.

### Rate Limits

**Free Tier**:
- 1,000 requests per day
- Rate limit: ~30 requests per minute

**Pro Tier** ($9/month):
- Unlimited requests
- Higher rate limits
- Faster inference

For production with many users, consider upgrading to Pro.

### Error Handling

The app handles these scenarios:
- Network errors
- API timeouts
- Invalid responses
- Rate limit exceeded
- Model loading (first request may be slow)

### Testing

Test the API integration:
```bash
curl https://api-inference.huggingface.co/models/meta-llama/Meta-Llama-3-8B-Instruct \
  -X POST \
  -H "Authorization: Bearer hf_YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"inputs": "Hello, how are you?"}'
```

---

## 📱 Speech-to-Text Integration

### Package: speech_to_text

**Version**: ^6.6.0

### Supported Languages
- English (en_US)
- Hindi (hi_IN)
- Spanish (es_ES)
- Chinese (zh_CN)
- French (fr_FR)
- German (de_DE)
- Arabic (ar_SA)
- Japanese (ja_JP)

### Permissions Required

**Android**: `RECORD_AUDIO` (already in AndroidManifest.xml)

**iOS**: `NSMicrophoneUsageDescription` (already in Info.plist)

### Usage Flow
1. User presses mic button
2. App requests microphone permission (first time)
3. Speech recognition starts
4. User speaks
5. Text is recognized in real-time
6. Final result sent to AI service

### Error Handling
- Permission denied → Show error message
- No speech detected → Prompt user to try again
- Network error → Show error message

---

## 🔊 Text-to-Speech Integration

### Package: flutter_tts

**Version**: ^3.10.0

### Features
- Multi-language support (8 languages)
- Mood-based voice modulation
- Pitch control (0.8 - 1.5)
- Rate control (0.3 - 1.0)
- Volume control (0.0 - 1.0)

### Mood-Based Voice Settings

| Mood Style | Rate | Pitch | Description |
|------------|------|-------|-------------|
| Chaos Energy | 0.65 | 1.2 | Fast, excited |
| Gentle Grandma | 0.4 | 0.9 | Slow, soothing |
| Permission Slip | 0.5 | 1.0 | Moderate, formal |
| Reality Check | 0.55 | 1.0 | Steady, clear |
| Micro Dare | 0.6 | 1.1 | Quick, motivating |

### Golden Voice Feature
When unlocked (via rewarded ad):
- Rate: 0.9× base rate (slower, more pleasant)
- Pitch: 1.1× base pitch (warmer tone)
- Duration: 1 hour

### Platform Support
- **Android**: Uses Android TTS engine
- **iOS**: Uses iOS AVSpeechSynthesizer

---

## 🔥 Firebase Remote Config

### Setup

1. Enable Remote Config in Firebase Console
2. Add parameters:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| force_update | Boolean | false | Force users to update |
| latest_version | String | 1.0.0 | Latest app version |
| update_message | String | "Update available..." | Custom update message |

### Usage Flow
1. App fetches config on splash screen
2. Compares current version with `latest_version`
3. If `force_update` is true and version is lower:
   - Show full-screen update dialog
   - Block app usage until update
   - Redirect to app store

### Update Strategy

**Minor Updates** (1.0.0 → 1.0.1):
- `force_update`: false
- Users can continue using app

**Major Updates** (1.0.0 → 2.0.0):
- `force_update`: true
- Users must update to continue

**Critical Fixes**:
- `force_update`: true
- Custom `update_message` explaining the issue

### Testing
1. Set `force_update` to true in Firebase Console
2. Set `latest_version` to "2.0.0"
3. Publish changes
4. Open app (version 1.0.0)
5. Should see update dialog

---

## 💰 AdMob Integration

### Ad Types

#### 1. Banner Ad
- **Position**: Bottom of screen
- **Size**: 320x50 (standard banner)
- **Visibility**: Always visible (except when ad-free)
- **Revenue**: Low eCPM (~$0.50-$2.00)

#### 2. Interstitial Ad
- **Trigger**: Every 4th shift
- **Skippable**: After 5 seconds
- **Revenue**: Medium eCPM (~$3.00-$8.00)

#### 3. Rewarded Ads (3 types)
- **Trigger**: After every successful shift
- **User Action**: Voluntary (user chooses to watch)
- **Revenue**: High eCPM (~$10.00-$30.00)

**Types**:
1. Make 2× Stronger - Replay with amplified voice
2. Unlock Golden Voice - Premium voice for 1 hour
3. Remove Ads 24h - Ad-free experience

### Revenue Projection

**Assumptions**:
- 1,000 daily active users
- 10 shifts per user per day
- 50% rewarded ad view rate

**Daily Revenue**:
- Banner: 1,000 users × $1.00 eCPM = $1.00
- Interstitial: 2,500 views × $5.00 eCPM = $12.50
- Rewarded: 5,000 views × $20.00 eCPM = $100.00

**Total**: ~$113.50/day = ~$3,400/month

### Optimization Tips

1. **Test Ad Placements**: A/B test different frequencies
2. **Monitor eCPM**: Track which ad types perform best
3. **User Experience**: Don't show too many ads (user retention > revenue)
4. **Rewarded Ads**: Make rewards valuable to increase view rate
5. **Ad Mediation**: Consider using multiple ad networks

### Test vs Production IDs

**Current (Test IDs)**:
- Safe for development
- No revenue
- Always available

**Production IDs**:
- Real revenue
- Must be approved by AdMob
- May take 1-2 hours to activate

**Important**: Replace ALL test IDs before production release!

---

## 🔐 Security Best Practices

### API Keys
- ✅ Store Hugging Face token in code (read-only token)
- ❌ Never commit Firebase config files to public repos
- ✅ Use environment variables for sensitive data (optional)

### User Data
- ✅ Store only necessary data locally (streak, preferences)
- ❌ Don't store voice recordings
- ❌ Don't send personal data to AI
- ✅ Clear data on app uninstall

### Network Security
- ✅ Use HTTPS for all API calls
- ✅ Validate API responses
- ✅ Handle errors gracefully
- ✅ Implement timeouts

---

## 📊 Monitoring & Analytics

### What to Monitor

1. **API Performance**
   - Response times
   - Error rates
   - Token usage

2. **Ad Performance**
   - Impressions
   - Click-through rate
   - eCPM
   - Fill rate

3. **User Engagement**
   - Daily active users
   - Shifts per user
   - Retention rate
   - Rewarded ad view rate

4. **Technical Metrics**
   - Crash rate
   - App size
   - Load times
   - Battery usage

### Tools

- **AdMob Dashboard**: Ad performance
- **Firebase Console**: Remote Config, Crashlytics
- **Hugging Face Dashboard**: API usage
- **App Store Connect / Play Console**: Downloads, reviews

---

## 🚀 Scaling Considerations

### When to Upgrade

**Hugging Face**:
- Free tier: Up to ~100 users/day
- Pro tier: 1,000+ users/day

**Firebase**:
- Spark (Free): Up to 10K users
- Blaze (Pay-as-you-go): Unlimited

**AdMob**:
- No limits, scales automatically

### Performance Optimization

1. **Cache AI Responses**: Store common responses locally
2. **Optimize Images**: Compress assets
3. **Lazy Loading**: Load services only when needed
4. **Background Processing**: Use isolates for heavy tasks

---

## 📞 Support & Resources

- **Hugging Face Docs**: https://huggingface.co/docs
- **Firebase Docs**: https://firebase.google.com/docs
- **AdMob Help**: https://support.google.com/admob
- **Flutter Docs**: https://flutter.dev/docs

---

**Last Updated**: 2025-11-22

