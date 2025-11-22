# MoodShift AI 🧠✨

A viral ADHD/mood shifter app with AI-powered voice responses. Built with Flutter and GetX.

## 🎯 Main Feature

**Hold the mic → Say anything → AI instantly gives a 10–30 second funny, kind, perfectly-timed voice response that fixes your brain**

### 5 AI Response Styles:
1. **Chaos Energy** - Hyper dares and energetic challenges
2. **Gentle Grandma** - Soft breathing and calming guidance
3. **Permission Slip** - Official permission to do (or not do) something
4. **Reality Check** - Kind, honest truth
5. **Micro Dare** - Tiny, achievable actions

## 💰 Monetization Strategy

### AdMob Integration:
- **Banner Ad**: Always visible at bottom (50dp height)
- **Interstitial Ad**: Every 4th shift (skippable after 5 sec)
- **Rewarded Ads** (3 types shown after EVERY shift):
  1. "Make this 2× stronger!" - Replay louder with confetti
  2. "Unlock Golden Voice 1 hour" - Premium warm voice
  3. "Remove ads for 24 hours" - Full ad-free experience

This setup generates 8-15 rewarded ad views per day per user willingly!

## 🚀 Features

- ✅ **Cross-Platform**: Full Android & iOS support
- ✅ **Multi-Language**: 8 languages (English, Hindi, Spanish, Chinese, French, German, Arabic, Japanese)
- ✅ **Screen Adaptation**: flutter_screenutil for all device sizes
- ✅ **Firebase Remote Config**: Force update mechanism
- ✅ **Voice I/O**: Speech-to-Text + Text-to-Speech with mood-based modulation
- ✅ **AI Integration**: Hugging Face LLM (Meta-Llama-3-8B-Instruct)
- ✅ **Local Streak Tracking**: Day counter and daily shifts
- ✅ **Beautiful UI**: Dark blue-purple gradient with animations

## 📋 Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / Xcode
- Firebase account
- Hugging Face API token
- AdMob account

## 🛠️ Setup Instructions

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd mood_shift_ai
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Setup Firebase

#### Option A: Using FlutterFire CLI (Recommended)
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

#### Option B: Manual Setup
1. Create a Firebase project at https://console.firebase.google.com/
2. Add Android app with package name: `com.moodshift.ai`
3. Add iOS app with bundle ID: `com.moodshift.ai`
4. Download `google-services.json` (Android) and place in `android/app/`
5. Download `GoogleService-Info.plist` (iOS) and place in `ios/Runner/`
6. Update `lib/firebase_options.dart` with your Firebase configuration

### 4. Setup Hugging Face API

1. Get your API token from https://huggingface.co/settings/tokens
2. Open `lib/app/services/ai_service.dart`
3. Replace `YOUR_HUGGING_FACE_API_TOKEN` with your actual token:
```dart
static const String _apiToken = 'hf_your_actual_token_here';
```

### 5. Setup AdMob

1. Create an AdMob account at https://admob.google.com/
2. Create ad units for:
   - Banner Ad
   - Interstitial Ad
   - Rewarded Ad (create 3 instances)
3. Update ad unit IDs in `lib/app/services/ad_service.dart`
4. Update AdMob App IDs:
   - Android: `android/app/src/main/AndroidManifest.xml`
   - iOS: `ios/Runner/Info.plist`

**Note**: The app currently uses test ad unit IDs. Replace them with your production IDs before release.

### 6. Add Required Assets

#### Fonts
Download Poppins font from [Google Fonts](https://fonts.google.com/specimen/Poppins) and place in `assets/fonts/`:
- `Poppins-Regular.ttf`
- `Poppins-Medium.ttf`
- `Poppins-SemiBold.ttf`
- `Poppins-Bold.ttf`

#### Images
Create or add a splash logo:
- `assets/images/splash_logo.png` (512x512 px recommended)

### 7. Generate Splash Screen
```bash
flutter pub run flutter_native_splash:create
```

### 8. Setup Remote Config (Optional)

1. Go to Firebase Console → Remote Config
2. Add these parameters:
   - `force_update` (Boolean) - Default: false
   - `latest_version` (String) - Default: "1.0.0"
   - `update_message` (String) - Default: "A new version is available..."

## 🏃 Running the App

### Development Mode
```bash
# Android
flutter run

# iOS
flutter run
```

### Build for Production

#### Android APK
```bash
flutter build apk --release
```

#### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

#### iOS
```bash
flutter build ipa --release
```

## 📱 Platform-Specific Setup

### Android

1. **Signing**: Update `android/app/build.gradle` with your signing configuration
2. **Permissions**: Already configured in `AndroidManifest.xml`
3. **ProGuard**: Rules already added in `android/app/proguard-rules.pro`

### iOS

1. **Signing**: Open `ios/Runner.xcworkspace` in Xcode and configure signing
2. **Permissions**: Already configured in `Info.plist`
3. **Pods**: Run `cd ios && pod install`

## 🌍 Supported Languages

1. English (en_US)
2. Hindi (hi_IN)
3. Spanish (es_ES)
4. Chinese (zh_CN)
5. French (fr_FR)
6. German (de_DE)
7. Arabic (ar_SA)
8. Japanese (ja_JP)

## 📂 Project Structure

```
lib/
├── app/
│   ├── modules/
│   │   ├── splash/          # Splash screen
│   │   ├── home/            # Main feature screen
│   │   └── settings/        # Settings screen
│   ├── routes/              # App routes
│   ├── services/            # Core services
│   │   ├── ai_service.dart
│   │   ├── speech_service.dart
│   │   ├── tts_service.dart
│   │   ├── ad_service.dart
│   │   ├── storage_service.dart
│   │   └── remote_config_service.dart
│   └── translations/        # Multi-language support
├── firebase_options.dart
└── main.dart
```

## 🔧 Configuration Files

- `pubspec.yaml` - Dependencies and assets
- `android/app/build.gradle` - Android build configuration
- `ios/Podfile` - iOS dependencies
- `lib/firebase_options.dart` - Firebase configuration

## 🎨 UI/UX Features

- Dark blue-purple gradient background
- Pulsing mic button with animations
- Real-time status updates
- Confetti animation on shift completion
- Streak tracking display
- Rewarded ad buttons with icons
- Force update dialog

## 🔐 Privacy & Permissions

### Android
- `INTERNET` - For API calls
- `RECORD_AUDIO` - For voice input
- `MODIFY_AUDIO_SETTINGS` - For TTS

### iOS
- `NSMicrophoneUsageDescription` - For voice input
- `NSSpeechRecognitionUsageDescription` - For speech recognition

## 📊 Analytics & Tracking

- Local streak tracking (no external analytics)
- Shift counter for ad frequency
- Ad-free period tracking
- Golden voice unlock tracking

## 🐛 Troubleshooting

### Common Issues

1. **Build fails**: Run `flutter clean && flutter pub get`
2. **Firebase errors**: Ensure `google-services.json` and `GoogleService-Info.plist` are in correct locations
3. **Ad not showing**: Check AdMob app IDs and ad unit IDs
4. **Voice not working**: Check microphone permissions
5. **iOS build fails**: Run `cd ios && pod install --repo-update`

## 📝 TODO Before Production

- [ ] Replace Firebase configuration with your project
- [ ] Replace Hugging Face API token
- [ ] Replace AdMob test IDs with production IDs
- [ ] Add app icons (use flutter_launcher_icons)
- [ ] Add privacy policy URL in settings
- [ ] Add app store URLs for rating
- [ ] Configure app signing for both platforms
- [ ] Test on multiple devices and screen sizes
- [ ] Setup Firebase Remote Config parameters
- [ ] Add analytics (optional)

## 📄 License

This project is private and proprietary.

## 🤝 Support

For issues or questions, please contact the development team.

---

Built with ❤️ using Flutter & GetX