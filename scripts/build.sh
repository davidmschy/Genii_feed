#!/bin/bash

# Genii Feed Build Script
# This script provides basic commands for cleaning, getting dependencies,
# and building the Flutter application.

echo "🚀 Genii Feed Build Script 🚀"
echo ""

# Exit immediately if a command exits with a non-zero status.
set -e

echo "🧹 Cleaning Flutter project..."
flutter clean
echo "✅ Clean complete."
echo ""

echo "📦 Getting Flutter dependencies..."
flutter pub get
echo "✅ Dependencies fetched."
echo ""

# --- Web Build ---
echo "🕸️ Building for Web (Release Mode)..."
flutter build web --release
echo "✅ Web build complete. Output in build/web"
echo ""

# --- Optional: Android Build (Uncomment to use) ---
# echo "🤖 Building Android APK (Release Mode)..."
# flutter build apk --release
# # flutter build appbundle --release # For App Bundle
# echo "✅ Android build complete. Output in build/app/outputs/flutter-apk/"
# echo ""

# --- Optional: iOS Build (Uncomment to use) ---
# Note: iOS builds typically require macOS and Xcode.
# echo "🍎 Building for iOS (Release Mode)..."
# flutter build ios --release --no-codesign # Add --no-codesign if you're not setting up signing yet
# echo "✅ iOS build complete. Output in build/ios/iphoneos/"
# echo ""

echo "🎉 All planned build steps in this script are done! 🎉"
echo "👉 Review output above for any errors."
echo "👉 Find web build in: build/web"
# echo "👉 Find Android APK in: build/app/outputs/flutter-apk/app-release.apk"
# echo "👉 Find iOS app in: build/ios/iphoneos/Runner.app (or use Xcode to archive)"
