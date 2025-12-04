# Local Backend Implementation Documentation

This document describes how all features were implemented locally in Flutter before migrating to Firebase Cloud Functions.

## Overview

The MoodShift AI app originally processed all AI and TTS operations locally on the device:
- **LLM Processing**: Direct API calls to Groq from Flutter
- **TTS Synthesis**: Direct API calls to AWS Polly from Flutter
- **Caching**: Local storage using GetStorage

## Services Architecture

### 1. GroqLLMService (`lib/app/services/groq_llm_service.dart`)

**Purpose**: Handles all LLM (Large Language Model) interactions with Groq API.

**Key Features**:
- Direct HTTP calls to Groq API (`https://api.groq.com/openai/v1/chat/completions`)
- Model: `llama-3.3-70b-versatile`
- Conversation history management (last 3 inputs/responses)
- Response caching based on user input
- Fallback responses when API fails
- JSON parsing for structured responses

**Key Methods**:
```dart
Future<String> generateResponse(String userInput, String language)
Future<String> generateStrongerResponse(String originalResponse, MoodStyle style, String language)
```

**Prompt Structure**:
- System prompt defines 5 mood styles (chaosEnergy, gentleGrandma, permissionSlip, realityCheck, microDare)
- Randomly selects a style for each response
- Includes conversation history to avoid repetition
- Returns JSON with `response` and `prosody` (rate, pitch, volume)

**Caching Logic**:
- Cache key: `userInput.toLowerCase() + language`
- Stores in local GetStorage
- Returns cached response if found

### 2. PollyTTSService (`lib/app/services/polly_tts_service.dart`)

**Purpose**: Handles text-to-speech synthesis using AWS Polly.

**Key Features**:
- AWS SigV4 authentication for Polly API
- Voice discovery and testing per locale
- Three engine types: generative, neural, standard (with fallback)
- SSML generation for prosody control
- Crystal voice mode (warmer, slower)
- 2x Stronger mode (amplified prosody)
- Fallback to device TTS if Polly fails

**Key Methods**:
```dart
Future<void> speak(String text, MoodStyle style, {Map<String, String>? prosody})
Future<void> speakStronger(String text, MoodStyle style, {Map<String, String>? prosody})
```

**Voice Selection**:
- Discovers available voices for current locale
- Tests voices to find working ones
- Caches voice map in local storage
- Prefers generative > neural > standard engines

**SSML Generation**:
- Different SSML for each engine type
- Generative: Uses `<amazon:effect name="drc">` for dynamic range compression
- Neural: Uses `<prosody>` tags for rate/pitch/volume
- Standard: Basic `<prosody>` tags

**Crystal Voice Mode**:
- Slower rate (0.85x)
- Warmer pitch adjustments
- Softer volume
- Special SSML with `<amazon:effect vocal-tract-length>`

**2x Stronger Mode**:
- Faster rate (1.3x)
- Higher pitch
- Louder volume
- Style-specific amplification

### 3. StorageService (`lib/app/services/storage_service.dart`)

**Purpose**: Local storage for app settings and cached data.

**Key Data Stored**:
- Language/locale settings
- Voice gender preference
- Streak data (current, longest, last shift date)
- Ad-free period
- Crystal voice period
- Conversation history (last 3 inputs/responses)
- Cached responses
- Polly voice map
- Cloud Functions feature flag

### 4. TTSService (`lib/app/services/tts_service.dart`)

**Purpose**: Fallback TTS using device's built-in text-to-speech.

**Used When**:
- AWS Polly fails
- Network unavailable
- As backup for audio playback failures

### 5. AIService (`lib/app/services/ai_service.dart`)

**Purpose**: Legacy service (HuggingFace API) - likely unused.

**Contains**:
- `MoodStyle` enum definition (used throughout app)
- HuggingFace API integration (deprecated)

## Feature Implementation Details

### Main Response Flow (Local)

1. User speaks → SpeechService captures text
2. HomeController calls `_processUserInputLocal()`
3. GroqLLMService.generateResponse() called with user text + language
4. Response cached in StorageService
5. PollyTTSService.speak() synthesizes audio
6. Audio played via AudioPlayer

### 2x Stronger Flow (Local)

1. User watches rewarded ad
2. HomeController calls `_handleStrongerLocal()`
3. GroqLLMService.generateStrongerResponse() called with original response
4. PollyTTSService.speakStronger() synthesizes with amplified prosody
5. Audio played with visual effects

### Crystal Voice Flow (Local)

1. User watches rewarded ad → Crystal voice activated for 1 hour
2. StorageService.setCrystalVoice1Hour() stores expiry
3. PollyTTSService checks `hasCrystalVoice()` before synthesis
4. Uses special SSML with warmer, slower prosody

## Files to Remove After Migration

### Services (Local Backend Logic):
- `lib/app/services/groq_llm_service.dart` - Local LLM service
- `lib/app/services/polly_tts_service.dart` - Local TTS service
- `lib/app/services/ai_service.dart` - Legacy HuggingFace service
- `lib/app/services/tts_service.dart` - Device TTS fallback

### Keep These Services:
- `lib/app/services/cloud_ai_service.dart` - Firebase Cloud Functions
- `lib/app/services/audio_player_service.dart` - Plays audio from URLs
- `lib/app/services/storage_service.dart` - Local settings (still needed)
- `lib/app/services/speech_service.dart` - Speech recognition (still needed)

## Migration Notes

1. **MoodStyle enum**: Move to a shared location (currently in ai_service.dart)
2. **Conversation history**: No longer needed locally (handled by Firebase)
3. **Response caching**: Handled by Firebase Storage
4. **Voice selection**: Handled by Firebase Cloud Functions
5. **SSML generation**: Handled by Firebase Cloud Functions

