# MoodShift AI - Troubleshooting Guide

## 🔧 Common Issues & Solutions

### Build & Setup Issues

#### ❌ "Flutter command not found"
**Problem**: Flutter is not installed or not in PATH

**Solution**:
```bash
# Install Flutter from https://flutter.dev/docs/get-started/install
# Add to PATH (macOS/Linux):
export PATH="$PATH:`pwd`/flutter/bin"

# Verify:
flutter doctor
```

---

#### ❌ "Pub get failed"
**Problem**: Dependencies can't be downloaded

**Solution**:
```bash
# Clear cache
flutter clean
rm -rf pubspec.lock

# Try again
flutter pub get

# If still fails, check internet connection
# Or try with VPN if in restricted region
```

---

#### ❌ "Assets not found" error
**Problem**: Required fonts or images missing

**Solution**:
1. Check `assets/fonts/` has all 4 Poppins font files
2. Check `assets/images/splash_logo.png` exists
3. Run `flutter clean && flutter pub get`

**Quick fix** - Create placeholder:
```bash
# Create a simple placeholder image
touch assets/images/splash_logo.png
```

---

### Firebase Issues

#### ❌ "Firebase initialization failed"
**Problem**: Firebase not configured properly

**Solution**:
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Configure project
flutterfire configure
```

**Alternative**: Skip Firebase for testing
- App will work without Remote Config
- Force update feature won't work

---

#### ❌ "google-services.json not found"
**Problem**: Android Firebase config missing

**Solution**:
1. Go to Firebase Console
2. Add Android app with package: `com.moodshift.ai`
3. Download `google-services.json`
4. Place in `android/app/` directory
5. Run `flutter clean && flutter pub get`

---

#### ❌ "GoogleService-Info.plist not found"
**Problem**: iOS Firebase config missing

**Solution**:
1. Go to Firebase Console
2. Add iOS app with bundle ID: `com.moodshift.ai`
3. Download `GoogleService-Info.plist`
4. Place in `ios/Runner/` directory
5. Run `flutter clean && flutter pub get`

---

### Voice & Microphone Issues

#### ❌ "Microphone permission denied"
**Problem**: User denied microphone access

**Solution**:

**Android**:
1. Settings → Apps → MoodShift AI → Permissions
2. Enable Microphone
3. Restart app

**iOS**:
1. Settings → MoodShift AI → Microphone
2. Enable
3. Restart app

**In code**: Already handled in `speech_service.dart`

---

#### ❌ "Speech recognition not working"
**Problem**: Voice input not detecting speech

**Solution**:
1. **Test on real device** (not emulator)
2. Check microphone permission
3. Check internet connection (required for speech recognition)
4. Speak clearly and loudly
5. Check device volume

**Debug**:
```dart
// In speech_service.dart, add logging:
print('Speech recognition available: ${await _speech.initialize()}');
```

---

#### ❌ "TTS not speaking"
**Problem**: Voice output not working

**Solution**:
1. Check device volume
2. Check device is not in silent mode
3. Test on real device
4. Check TTS engine installed (Android)

**Android specific**:
- Settings → Accessibility → Text-to-speech
- Install Google TTS if needed

**iOS specific**:
- Should work out of the box
- Check device language settings

---

### AI & API Issues

#### ❌ "AI response is empty or error"
**Problem**: Hugging Face API not working

**Solution**:
1. **Check API token** in `lib/app/services/ai_service.dart` line 17
2. Verify token is valid: https://huggingface.co/settings/tokens
3. Check internet connection
4. Check API rate limits (1000 requests/day on free tier)

**Test API manually**:
```bash
curl https://api-inference.huggingface.co/models/meta-llama/Meta-Llama-3-8B-Instruct \
  -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"inputs": "Hello"}'
```

**Fallback**: App uses pre-written responses if API fails

---

#### ❌ "Model is loading" error
**Problem**: Hugging Face model needs to warm up

**Solution**:
- First request may take 20-30 seconds
- Wait and try again
- Model stays warm for ~5 minutes
- This is normal for free tier

---

### Ad Issues

#### ❌ "Ads not showing"
**Problem**: AdMob ads not displaying

**Solution**:

**For Test Ads** (current setup):
- Test ads may take 1-2 minutes to load first time
- Check internet connection
- Restart app

**For Production Ads**:
1. Verify AdMob account is approved
2. Check ad unit IDs are correct
3. Wait 1-2 hours after creating ad units
4. Check AdMob dashboard for errors

**Debug**:
```dart
// In ad_service.dart, check logs:
print('Banner ad loaded: ${_bannerAd != null}');
```

---

#### ❌ "Ad failed to load" error
**Problem**: Ad request failed

**Common causes**:
- No internet connection
- Ad inventory empty (rare)
- Invalid ad unit ID
- App not approved in AdMob

**Solution**:
1. Check internet
2. Verify ad unit IDs
3. Check AdMob dashboard
4. Wait and retry (ads auto-reload)

---

### Build Issues

#### ❌ Android build fails
**Problem**: Gradle build errors

**Solution**:
```bash
# Clean build
flutter clean
cd android
./gradlew clean
cd ..

# Update Gradle
cd android
./gradlew wrapper --gradle-version 7.5
cd ..

# Rebuild
flutter build apk --release
```

**Common fixes**:
- Update Android SDK
- Update Gradle version
- Check `android/app/build.gradle` for errors
- Ensure Java 11+ installed

---

#### ❌ iOS build fails
**Problem**: Xcode build errors

**Solution**:
```bash
# Clean build
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod deintegrate
pod install --repo-update
cd ..

# Rebuild
flutter build ios --release
```

**Common fixes**:
- Update Xcode to latest version
- Update CocoaPods: `sudo gem install cocoapods`
- Check signing certificates in Xcode
- Ensure macOS is up to date

---

#### ❌ "Signing for iOS requires a development team"
**Problem**: No Apple Developer account configured

**Solution**:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner → Signing & Capabilities
3. Select your team (or create free account)
4. Xcode will auto-manage signing

---

### Runtime Issues

#### ❌ App crashes on launch
**Problem**: Initialization error

**Solution**:
1. Check logs: `flutter logs`
2. Common causes:
   - Firebase not initialized
   - Missing assets
   - Permission issues

**Debug**:
```bash
# Run in debug mode
flutter run --debug

# Check logs
flutter logs
```

---

#### ❌ "GetStorage initialization failed"
**Problem**: Local storage can't initialize

**Solution**:
```bash
# Clear app data
# Android: Settings → Apps → MoodShift AI → Clear Data
# iOS: Delete and reinstall app

# Or in code, already handled with try-catch
```

---

#### ❌ Language not changing
**Problem**: Translation not updating

**Solution**:
1. Check translation file exists for that language
2. Restart app after changing language
3. Clear app cache

**Debug**:
```dart
// In settings_controller.dart:
print('Current locale: ${Get.locale}');
```

---

### Performance Issues

#### ❌ App is slow or laggy
**Problem**: Performance issues

**Solution**:
1. **Test on real device** (emulators are slower)
2. Build in release mode: `flutter run --release`
3. Check for memory leaks
4. Optimize images (compress assets)

**Profile performance**:
```bash
flutter run --profile
# Then use DevTools to analyze
```

---

#### ❌ High battery usage
**Problem**: App draining battery

**Solution**:
1. Check for infinite loops
2. Dispose controllers properly (already done)
3. Stop services when not needed
4. Reduce animation frequency

---

### Network Issues

#### ❌ "No internet connection" error
**Problem**: Network requests failing

**Solution**:
1. Check device internet connection
2. Check API endpoints are accessible
3. Check firewall/VPN settings
4. Test on different network

**Debug**:
```dart
// Test connectivity
import 'package:connectivity_plus/connectivity_plus';
var result = await Connectivity().checkConnectivity();
print('Connection: $result');
```

---

### Platform-Specific Issues

#### ❌ Android: "Cleartext HTTP traffic not permitted"
**Problem**: HTTP requests blocked on Android 9+

**Solution**:
- Already configured in `AndroidManifest.xml`
- Uses `android:usesCleartextTraffic="true"`
- All APIs use HTTPS anyway

---

#### ❌ iOS: "App Transport Security" error
**Problem**: HTTP requests blocked on iOS

**Solution**:
- Already configured in `Info.plist`
- All APIs use HTTPS
- No additional config needed

---

## 🐛 Debugging Tips

### Enable Verbose Logging
```bash
flutter run -v
```

### Check Device Logs
```bash
# Android
adb logcat

# iOS
idevicesyslog
```

### Use Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### Common Debug Commands
```bash
# Check Flutter setup
flutter doctor -v

# Analyze code
flutter analyze

# Run tests
flutter test

# Clean build
flutter clean

# Update dependencies
flutter pub upgrade
```

---

## 📞 Getting Help

### Before Asking for Help

1. ✅ Check this troubleshooting guide
2. ✅ Read error messages carefully
3. ✅ Check Flutter logs: `flutter logs`
4. ✅ Try `flutter clean && flutter pub get`
5. ✅ Search error on Google/Stack Overflow

### Useful Resources

- **Flutter Docs**: https://flutter.dev/docs
- **GetX Docs**: https://pub.dev/packages/get
- **Stack Overflow**: https://stackoverflow.com/questions/tagged/flutter
- **Flutter Discord**: https://discord.gg/flutter
- **GitHub Issues**: Check package repositories

### Reporting Issues

When reporting issues, include:
1. Error message (full stack trace)
2. Flutter version: `flutter --version`
3. Device/OS version
4. Steps to reproduce
5. Expected vs actual behavior

---

## ✅ Prevention Tips

### Before Building
- [ ] Run `flutter doctor` and fix all issues
- [ ] Test on multiple devices
- [ ] Test all features thoroughly
- [ ] Check all API keys are correct
- [ ] Verify all assets are present

### During Development
- [ ] Commit code frequently
- [ ] Test after each major change
- [ ] Keep dependencies updated
- [ ] Monitor logs for warnings
- [ ] Use version control (Git)

### Before Release
- [ ] Complete `CONFIGURATION_CHECKLIST.md`
- [ ] Test on real devices (not emulators)
- [ ] Test all ad types
- [ ] Test all languages
- [ ] Test edge cases (no internet, no permission, etc.)
- [ ] Run `flutter analyze` (no errors)
- [ ] Build release version successfully

---

## 🎯 Quick Fixes Checklist

When something doesn't work, try these in order:

1. ✅ Restart app
2. ✅ `flutter clean && flutter pub get`
3. ✅ Restart IDE
4. ✅ Restart device
5. ✅ Delete app and reinstall
6. ✅ Check internet connection
7. ✅ Check permissions
8. ✅ Check API keys
9. ✅ Check logs
10. ✅ Read error message carefully

**90% of issues are solved by steps 1-5!**

---

**Still stuck? Check the documentation files or search online. Good luck! 🚀**

