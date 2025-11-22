# MoodShift AI - Configuration Checklist

Use this checklist to ensure everything is configured before building for production.

## ✅ Required Assets

- [ ] `assets/fonts/Poppins-Regular.ttf`
- [ ] `assets/fonts/Poppins-Medium.ttf`
- [ ] `assets/fonts/Poppins-SemiBold.ttf`
- [ ] `assets/fonts/Poppins-Bold.ttf`
- [ ] `assets/images/splash_logo.png`

## ✅ Firebase Configuration

- [ ] Firebase project created
- [ ] `android/app/google-services.json` added
- [ ] `ios/Runner/GoogleService-Info.plist` added
- [ ] `lib/firebase_options.dart` configured
- [ ] Remote Config enabled in Firebase Console
- [ ] Remote Config parameters added:
  - [ ] `force_update` (Boolean)
  - [ ] `latest_version` (String)
  - [ ] `update_message` (String)

## ✅ Hugging Face API

- [ ] Hugging Face account created
- [ ] API token generated
- [ ] Token added to `lib/app/services/ai_service.dart` (line 17)

## ✅ AdMob Configuration

### AdMob Account
- [ ] AdMob account created
- [ ] Android app registered in AdMob
- [ ] iOS app registered in AdMob

### Ad Units Created
- [ ] Android Banner Ad unit
- [ ] Android Interstitial Ad unit
- [ ] Android Rewarded Ad unit(s)
- [ ] iOS Banner Ad unit
- [ ] iOS Interstitial Ad unit
- [ ] iOS Rewarded Ad unit(s)

### Ad IDs Updated
- [ ] Banner ad unit IDs in `lib/app/services/ad_service.dart`
- [ ] Interstitial ad unit IDs in `lib/app/services/ad_service.dart`
- [ ] Rewarded ad unit IDs in `lib/app/services/ad_service.dart`
- [ ] AdMob App ID in `android/app/src/main/AndroidManifest.xml`
- [ ] AdMob App ID in `ios/Runner/Info.plist`

## ✅ App Information

- [ ] App name verified in all translation files
- [ ] Package name: `com.moodshift.ai` (or your custom package)
- [ ] Bundle ID: `com.moodshift.ai` (or your custom bundle)
- [ ] Version number in `pubspec.yaml`

## ✅ URLs & Links

- [ ] Privacy Policy URL in `lib/app/modules/settings/settings_controller.dart`
- [ ] Google Play Store URL in `lib/app/modules/settings/settings_controller.dart`
- [ ] Apple App Store URL in `lib/app/modules/settings/settings_controller.dart`

## ✅ App Icons

- [ ] App icon created (1024x1024 px)
- [ ] `flutter_launcher_icons` configured in `pubspec.yaml`
- [ ] Icons generated with `flutter pub run flutter_launcher_icons`

## ✅ Splash Screen

- [ ] Splash logo added to `assets/images/splash_logo.png`
- [ ] Splash screen generated with `flutter pub run flutter_native_splash:create`

## ✅ Android Configuration

- [ ] Package name verified in `android/app/build.gradle`
- [ ] Minimum SDK version: 21
- [ ] Target SDK version: 34
- [ ] Compile SDK version: 34
- [ ] ProGuard rules configured
- [ ] Permissions verified in `AndroidManifest.xml`

### Android Signing (for Release)
- [ ] Keystore created
- [ ] `android/key.properties` created
- [ ] Signing config added to `android/app/build.gradle`

## ✅ iOS Configuration

- [ ] Bundle ID verified in Xcode
- [ ] Deployment target: iOS 12.0+
- [ ] Permissions added to `Info.plist`
- [ ] SKAdNetwork items added for AdMob
- [ ] Pods installed (`cd ios && pod install`)

### iOS Signing (for Release)
- [ ] Apple Developer account ($99/year)
- [ ] Signing & Capabilities configured in Xcode
- [ ] Provisioning profile created

## ✅ Testing

### Functionality
- [ ] Voice input works on real device
- [ ] Voice output (TTS) works
- [ ] AI responses are appropriate
- [ ] All 5 mood styles work
- [ ] Language switching works (all 8 languages)
- [ ] Streak tracking works
- [ ] Settings screen functional

### Ads
- [ ] Banner ad displays at bottom
- [ ] Interstitial ad shows every 4th shift
- [ ] All 3 rewarded ad buttons work
- [ ] "Make 2× stronger" replays with confetti
- [ ] "Golden Voice" unlocks for 1 hour
- [ ] "Remove ads 24h" hides ads

### UI/UX
- [ ] Splash screen displays correctly
- [ ] Gradient background looks good
- [ ] Mic button animates on press
- [ ] Status text updates correctly
- [ ] Confetti plays on shift completion
- [ ] Rewarded buttons appear after shift
- [ ] All screens adapt to different screen sizes

### Edge Cases
- [ ] No internet connection handling
- [ ] Microphone permission denied handling
- [ ] No speech detected handling
- [ ] AI service error handling
- [ ] Ad loading failures handled gracefully

## ✅ Remote Config

- [ ] Force update tested
- [ ] Update dialog displays correctly
- [ ] App store links work from update dialog

## ✅ Privacy & Compliance

- [ ] Privacy policy created and hosted
- [ ] Privacy policy link works
- [ ] Microphone usage clearly explained
- [ ] Data collection disclosed (if any)
- [ ] COPPA compliance (if targeting children)
- [ ] GDPR compliance (if targeting EU)

## ✅ Store Listings

### Google Play Store
- [ ] Developer account created ($25 one-time)
- [ ] App created in Play Console
- [ ] Screenshots prepared (phone & tablet)
- [ ] Feature graphic created
- [ ] App description written
- [ ] Privacy policy link added
- [ ] Content rating completed
- [ ] Pricing & distribution set

### Apple App Store
- [ ] Developer account created ($99/year)
- [ ] App created in App Store Connect
- [ ] Screenshots prepared (all required sizes)
- [ ] App preview video (optional)
- [ ] App description written
- [ ] Keywords optimized
- [ ] Privacy policy link added
- [ ] Age rating completed
- [ ] Pricing & availability set

## ✅ Pre-Launch

- [ ] All test ad IDs replaced with production IDs
- [ ] Debug logging removed/disabled
- [ ] App tested on multiple devices
- [ ] App tested on different Android versions
- [ ] App tested on different iOS versions
- [ ] Performance tested (no lag, smooth animations)
- [ ] Battery usage acceptable
- [ ] App size optimized
- [ ] Crash testing completed
- [ ] Beta testing completed (optional but recommended)

## ✅ Build for Release

- [ ] Version number incremented
- [ ] Build number incremented
- [ ] Android APK built: `flutter build apk --release`
- [ ] Android AAB built: `flutter build appbundle --release`
- [ ] iOS IPA built: `flutter build ipa --release`
- [ ] Release builds tested on real devices

## ✅ Post-Launch

- [ ] Monitor crash reports
- [ ] Monitor ad performance in AdMob
- [ ] Monitor user reviews
- [ ] Respond to user feedback
- [ ] Plan updates and improvements
- [ ] Monitor Remote Config for force updates

---

## 📝 Notes

Use this space to track any custom configurations or notes:

```
[Your notes here]
```

---

**Last Updated**: [Date]
**Reviewed By**: [Name]
**Status**: [ ] Ready for Production / [ ] Needs Work

