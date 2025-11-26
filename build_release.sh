#!/bin/bash

# MoodShift AI - Release Build Script
# This script builds both Android and iOS release versions

echo "🚀 MoodShift AI - Release Build Script"
echo "========================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null
then
    echo -e "${RED}❌ Flutter is not installed. Please install Flutter first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Flutter found${NC}"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
echo ""

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get
echo ""

# Check for required assets
echo "🔍 Checking required assets..."

MISSING_ASSETS=false

if [ ! -f "assets/fonts/Poppins-Regular.ttf" ]; then
    echo -e "${RED}❌ Missing: assets/fonts/Poppins-Regular.ttf${NC}"
    MISSING_ASSETS=true
fi

if [ ! -f "assets/fonts/Poppins-Medium.ttf" ]; then
    echo -e "${RED}❌ Missing: assets/fonts/Poppins-Medium.ttf${NC}"
    MISSING_ASSETS=true
fi

if [ ! -f "assets/fonts/Poppins-SemiBold.ttf" ]; then
    echo -e "${RED}❌ Missing: assets/fonts/Poppins-SemiBold.ttf${NC}"
    MISSING_ASSETS=true
fi

if [ ! -f "assets/fonts/Poppins-Bold.ttf" ]; then
    echo -e "${RED}❌ Missing: assets/fonts/Poppins-Bold.ttf${NC}"
    MISSING_ASSETS=true
fi

if [ ! -f "assets/images/splash_logo.png" ]; then
    echo -e "${YELLOW}⚠️  Missing: assets/images/splash_logo.png (optional but recommended)${NC}"
fi

if [ "$MISSING_ASSETS" = true ]; then
    echo ""
    echo -e "${RED}Please add the missing assets before building.${NC}"
    echo "See assets/README.md for details."
    exit 1
fi

echo -e "${GREEN}✅ All required assets found${NC}"
echo ""

# Check Firebase configuration
echo "🔍 Checking Firebase configuration..."

if [ ! -f "android/app/google-services.json" ]; then
    echo -e "${YELLOW}⚠️  Warning: android/app/google-services.json not found${NC}"
    echo "   Run 'flutterfire configure' to set up Firebase"
fi

if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${YELLOW}⚠️  Warning: ios/Runner/GoogleService-Info.plist not found${NC}"
    echo "   Run 'flutterfire configure' to set up Firebase"
fi

echo ""

# Build Android
echo "📱 Building Android APK..."
flutter build apk --release

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Android APK built successfully!${NC}"
    echo "   Location: build/app/outputs/flutter-apk/app-release.apk"
else
    echo -e "${RED}❌ Android APK build failed${NC}"
fi

echo ""

# Build Android App Bundle
echo "📦 Building Android App Bundle..."
flutter build appbundle --release

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Android App Bundle built successfully!${NC}"
    echo "   Location: build/app/outputs/bundle/release/app-release.aab"
else
    echo -e "${RED}❌ Android App Bundle build failed${NC}"
fi

echo ""

# Build iOS (only on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Building iOS IPA..."
    
    # Install pods
    cd ios
    pod install
    cd ..
    
    flutter build ipa --release
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ iOS IPA built successfully!${NC}"
        echo "   Open Xcode to upload to App Store Connect"
    else
        echo -e "${RED}❌ iOS IPA build failed${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  iOS build skipped (macOS required)${NC}"
fi

echo ""
echo "========================================"
echo -e "${GREEN}🎉 Build process completed!${NC}"
echo "========================================"

