# MoodShift AI - Quick Start Guide

## ⚡ Get Running in 10 Minutes

### 1. Prerequisites Check
```bash
flutter doctor
```
Make sure you have:
- ✅ Flutter SDK installed
- ✅ Android Studio or Xcode
- ✅ Device/Emulator ready

### 2. Install Dependencies
```bash
cd mood_shift_ai
flutter pub get
```

### 3. Add Required Assets

#### Download Fonts (2 minutes)
1. Go to: https://fonts.google.com/specimen/Poppins
2. Click "Download family"
3. Extract and copy these 4 files to `assets/fonts/`:
   - `Poppins-Regular.ttf`
   - `Poppins-Medium.ttf`
   - `Poppins-SemiBold.ttf`
   - `Poppins-Bold.ttf`

#### Create Splash Logo (1 minute)
1. Create any 512x512 image (or download from https://placeholder.com/)
2. Save as `assets/images/splash_logo.png`

### 4. Setup Firebase (3 minutes)

**Option A - FlutterFire CLI (Recommended)**:
```bash
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```

**Option B - Skip for now**:
The app will run with placeholder Firebase config (some features won't work)

### 5. Add Hugging Face Token (1 minute)
1. Get free token: https://huggingface.co/settings/tokens
2. Open `lib/app/services/ai_service.dart`
3. Line 17: Replace `YOUR_HUGGING_FACE_API_TOKEN` with your token

### 6. Run the App! 🚀
```bash
flutter run
```

---

## 🎯 What Works Out of the Box

✅ **Working**:
- Beautiful UI with animations
- Voice input (Speech-to-Text)
- Voice output (Text-to-Speech)
- AI responses (if Hugging Face token added)
- Multi-language support (8 languages)
- Settings screen
- Streak tracking
- Test ads (AdMob test IDs)

⚠️ **Needs Configuration**:
- Firebase Remote Config (force update won't work)
- Production AdMob IDs (currently using test IDs)
- Privacy policy URL
- App store URLs

---

## 📱 Test the App

### Test Voice Flow
1. Tap and hold the mic button
2. Say anything (e.g., "I'm bored")
3. Release the mic
4. Wait for AI response
5. Listen to voice output
6. See confetti animation 🎉
7. See 3 rewarded ad buttons

### Test Language Switching
1. Tap settings icon (top right)
2. Tap "Language"
3. Select any language
4. UI updates instantly

### Test Ads
1. Banner ad at bottom (always visible)
2. Interstitial ad after 4th shift
3. Rewarded ads (tap any of the 3 buttons)

---

## 🔧 Common First-Run Issues

### Issue: "Assets not found"
**Fix**: Make sure fonts and splash logo are in correct folders

### Issue: "Firebase error"
**Fix**: Run `flutterfire configure` or ignore for now (app still works)

### Issue: "Microphone permission denied"
**Fix**: 
- Android: Check Settings → Apps → MoodShift AI → Permissions
- iOS: Check Settings → MoodShift AI → Microphone

### Issue: "No AI response"
**Fix**: Add Hugging Face API token in `lib/app/services/ai_service.dart`

### Issue: "Build fails"
**Fix**: 
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🚀 Next Steps

### For Development
- ✅ App is ready to develop and test
- ✅ All features work with test data
- ✅ Safe to experiment and modify

### For Production
See these guides:
1. `CONFIGURATION_CHECKLIST.md` - Complete checklist
2. `SETUP_GUIDE.md` - Detailed setup
3. `API_INTEGRATION_GUIDE.md` - API details
4. `README.md` - Full documentation

---

## 📂 Project Files Overview

```
mood_shift_ai/
├── lib/
│   ├── app/
│   │   ├── modules/        # Screens (splash, home, settings)
│   │   ├── services/       # Core logic (AI, voice, ads)
│   │   ├── translations/   # 8 languages
│   │   └── routes/         # Navigation
│   ├── main.dart           # App entry point
│   └── firebase_options.dart
├── android/                # Android config
├── ios/                    # iOS config
├── assets/                 # Fonts, images, animations
├── pubspec.yaml            # Dependencies
└── Documentation files
```

---

## 🎨 Customization Ideas

### Easy Changes
- Change gradient colors in `home_view.dart` and `splash_view.dart`
- Modify AI response styles in `ai_service.dart`
- Add more languages in `translations/`
- Adjust voice pitch/rate in `tts_service.dart`

### Medium Changes
- Add new rewarded ad options
- Create custom animations
- Add more AI personality styles
- Implement user profiles

### Advanced Changes
- Add backend server
- Implement social features
- Create premium subscription
- Add analytics

---

## 💡 Tips for Success

1. **Test on Real Devices**: Voice features work best on real devices
2. **Start Simple**: Get basic flow working before adding features
3. **Monitor Logs**: Use `flutter logs` to debug issues
4. **Iterate Fast**: Make small changes and test frequently
5. **User Feedback**: Test with real users early

---

## 📊 Key Metrics to Watch

While developing:
- App launch time (should be <3 seconds)
- Voice recognition accuracy
- AI response quality
- UI smoothness (60 FPS)
- Battery usage

---

## 🆘 Need Help?

### Documentation
- `README.md` - Main docs
- `SETUP_GUIDE.md` - Detailed setup
- `PROJECT_SUMMARY.md` - Overview
- `API_INTEGRATION_GUIDE.md` - API details

### Resources
- Flutter Docs: https://flutter.dev/docs
- GetX Docs: https://pub.dev/packages/get
- Firebase Docs: https://firebase.google.com/docs
- Hugging Face: https://huggingface.co/docs

### Debugging
```bash
# View logs
flutter logs

# Clean build
flutter clean

# Check dependencies
flutter pub get

# Analyze code
flutter analyze

# Run tests
flutter test
```

---

## ✅ You're Ready!

Your MoodShift AI app is now running! 🎉

**What to do next**:
1. Play with the app
2. Test all features
3. Customize to your liking
4. When ready for production, follow `CONFIGURATION_CHECKLIST.md`

**Happy coding! 🚀**

---

**Quick Commands Reference**:
```bash
# Run app
flutter run

# Build APK
flutter build apk --release

# Build iOS
flutter build ipa --release

# Clean
flutter clean

# Get dependencies
flutter pub get

# Generate splash
flutter pub run flutter_native_splash:create
```

