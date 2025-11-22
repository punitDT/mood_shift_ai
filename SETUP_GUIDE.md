# MoodShift AI - Complete Setup Guide

## 🚀 Quick Start (5 Minutes)

### Step 1: Install Flutter
If you haven't already, install Flutter from https://flutter.dev/docs/get-started/install

Verify installation:
```bash
flutter doctor
```

### Step 2: Get Dependencies
```bash
cd mood_shift_ai
flutter pub get
```

### Step 3: Add Required Assets

#### Download Poppins Font
1. Go to https://fonts.google.com/specimen/Poppins
2. Click "Download family"
3. Extract and copy these files to `assets/fonts/`:
   - `Poppins-Regular.ttf`
   - `Poppins-Medium.ttf`
   - `Poppins-SemiBold.ttf`
   - `Poppins-Bold.ttf`

#### Create Splash Logo
1. Create a simple logo image (512x512 px)
2. Save as `assets/images/splash_logo.png`
3. Or use a placeholder from https://placeholder.com/

### Step 4: Firebase Setup (CRITICAL)

#### Using FlutterFire CLI (Easiest):
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Configure your project
flutterfire configure
```

This will:
- Create a Firebase project (or select existing)
- Register Android and iOS apps
- Download configuration files
- Generate `lib/firebase_options.dart`

#### Manual Setup (Alternative):
1. Go to https://console.firebase.google.com/
2. Create new project: "MoodShift AI"
3. Add Android app:
   - Package name: `com.moodshift.ai`
   - Download `google-services.json`
   - Place in `android/app/`
4. Add iOS app:
   - Bundle ID: `com.moodshift.ai`
   - Download `GoogleService-Info.plist`
   - Place in `ios/Runner/`
5. Enable Remote Config in Firebase Console

### Step 5: Hugging Face API Token

1. Create account at https://huggingface.co/
2. Go to https://huggingface.co/settings/tokens
3. Create new token (read access is enough)
4. Copy token
5. Open `lib/app/services/ai_service.dart`
6. Replace line 17:
```dart
static const String _apiToken = 'hf_YOUR_ACTUAL_TOKEN_HERE';
```

### Step 6: Run the App!

```bash
# For Android
flutter run

# For iOS (Mac only)
flutter run
```

## 🎯 Production Setup

### 1. AdMob Configuration

#### Create AdMob Account
1. Go to https://admob.google.com/
2. Sign up / Sign in
3. Create new app for Android and iOS

#### Create Ad Units
Create these ad units:

**Android:**
- 1x Banner Ad
- 1x Interstitial Ad
- 3x Rewarded Ad (or use same ID for all 3)

**iOS:**
- 1x Banner Ad
- 1x Interstitial Ad
- 3x Rewarded Ad (or use same ID for all 3)

#### Update Ad Unit IDs

Open `lib/app/services/ad_service.dart` and replace test IDs:

```dart
String get bannerAdUnitId {
  if (Platform.isAndroid) {
    return 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY'; // Your Android banner ID
  } else if (Platform.isIOS) {
    return 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY'; // Your iOS banner ID
  }
  return '';
}

// Repeat for interstitialAdUnitId and rewardedAdUnitId
```

#### Update AdMob App IDs

**Android** - `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
```

**iOS** - `ios/Runner/Info.plist`:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
```

### 2. App Icons

Use `flutter_launcher_icons` package:

1. Add to `pubspec.yaml` (already in dev_dependencies)
2. Create icon image (1024x1024 px)
3. Add configuration to `pubspec.yaml`:
```yaml
flutter_icons:
  android: true
  ios: true
  image_path: "assets/images/app_icon.png"
```
4. Run: `flutter pub run flutter_launcher_icons`

### 3. App Signing

#### Android Signing

1. Create keystore:
```bash
keytool -genkey -v -keystore ~/moodshift-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias moodshift
```

2. Create `android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=moodshift
storeFile=/path/to/moodshift-release-key.jks
```

3. Update `android/app/build.gradle`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            ...
        }
    }
}
```

#### iOS Signing

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner → Signing & Capabilities
3. Select your team
4. Xcode will automatically manage signing

### 4. Privacy Policy & URLs

Update these in `lib/app/modules/settings/settings_controller.dart`:

```dart
// Privacy Policy URL
const url = 'https://your-website.com/privacy-policy';

// App Store URLs
const androidUrl = 'https://play.google.com/store/apps/details?id=com.moodshift.ai';
const iosUrl = 'https://apps.apple.com/app/id1234567890';
```

### 5. Firebase Remote Config

1. Go to Firebase Console → Remote Config
2. Add parameters:

| Parameter | Type | Default Value |
|-----------|------|---------------|
| force_update | Boolean | false |
| latest_version | String | 1.0.0 |
| update_message | String | A new version is available. Please update to continue using the app. |

3. Publish changes

### 6. Build for Release

#### Android APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

#### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

#### iOS
```bash
flutter build ipa --release
```
Then open Xcode and upload to App Store Connect.

## 🧪 Testing Checklist

Before releasing:

- [ ] Test on multiple Android devices (different screen sizes)
- [ ] Test on multiple iOS devices (iPhone & iPad)
- [ ] Test all 8 languages
- [ ] Test voice input/output
- [ ] Test all ad types (banner, interstitial, rewarded)
- [ ] Test force update mechanism
- [ ] Test streak tracking
- [ ] Test settings (language change, share, rate)
- [ ] Test offline behavior
- [ ] Test microphone permissions
- [ ] Verify privacy policy link works
- [ ] Verify app store links work

## 🐛 Common Issues & Solutions

### Issue: "google-services.json not found"
**Solution**: Make sure file is in `android/app/` directory

### Issue: "GoogleService-Info.plist not found"
**Solution**: Make sure file is in `ios/Runner/` directory

### Issue: Ads not showing
**Solution**: 
- Check AdMob app IDs are correct
- Wait 1-2 hours after creating ad units
- Test ads may take time to load first time

### Issue: Voice recognition not working
**Solution**: 
- Check microphone permissions
- Test on real device (not emulator)
- Check internet connection

### Issue: iOS build fails
**Solution**:
```bash
cd ios
pod deintegrate
pod install --repo-update
cd ..
flutter clean
flutter pub get
flutter build ios
```

### Issue: Firebase initialization error
**Solution**: 
- Verify `google-services.json` and `GoogleService-Info.plist` are correct
- Run `flutterfire configure` again
- Check package names match

## 📊 Monitoring & Analytics

### AdMob Dashboard
- Monitor ad performance
- Check eCPM rates
- Optimize ad placements

### Firebase Console
- Monitor Remote Config usage
- Check crash reports (if Crashlytics enabled)
- Monitor user engagement

## 🚀 Deployment

### Google Play Store
1. Create developer account ($25 one-time fee)
2. Create new app
3. Upload AAB file
4. Fill in store listing
5. Submit for review

### Apple App Store
1. Create developer account ($99/year)
2. Create app in App Store Connect
3. Upload IPA via Xcode or Transporter
4. Fill in app information
5. Submit for review

## 📈 Post-Launch

### Update Strategy
1. Increment version in `pubspec.yaml`
2. Build new release
3. Upload to stores
4. Update Remote Config `latest_version`
5. Set `force_update` to true if critical

### Monetization Optimization
- Monitor which rewarded ads perform best
- Adjust interstitial frequency if needed
- Test different ad networks
- Consider in-app purchases for premium features

## 🎉 You're Ready!

Your MoodShift AI app is now ready for production. Good luck with your launch! 🚀

