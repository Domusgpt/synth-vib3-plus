# Build Instructions

This document provides instructions for building the Synth-VIB3+ APK locally and via GitHub Actions.

## Option 1: Automated Build via GitHub Actions (Recommended)

The easiest way to get an APK is to let GitHub Actions build it automatically:

### How it Works

1. **Automatic Build**: GitHub Actions automatically builds an APK whenever you push to a `claude/**` branch
2. **Download Artifacts**: After the build completes (~5-10 minutes), download the APK from:
   - Go to the [Actions tab](https://github.com/Domusgpt/synth-vib3-plus/actions)
   - Click on the most recent "Build Android APK" workflow run
   - Scroll down to "Artifacts"
   - Download `synth-vib3-plus-release`

3. **Releases**: Builds from claude branches create pre-release versions with:
   - Automatic versioning based on date and commit hash
   - Direct APK download link
   - Build information and testing instructions

### Trigger a Build

```bash
# Make any change and push
git commit --allow-empty -m "Trigger APK build"
git push origin claude/refactor-synthesizer-visualizer-012K7EbKVyBNNLXNfXwUgF3r
```

Then check the Actions tab for your build.

## Option 2: Build Locally

### Prerequisites

1. **Flutter SDK 3.38.1+**
   ```bash
   # Download from https://flutter.dev/docs/get-started/install
   # Or use flutter version manager (fvm)
   ```

2. **Android SDK**
   - Install Android Studio: https://developer.android.com/studio
   - Or install command-line tools only
   - Accept Android licenses: `flutter doctor --android-licenses`

3. **Java 17+**
   ```bash
   # Ubuntu/Debian
   sudo apt install openjdk-17-jdk

   # macOS (using Homebrew)
   brew install openjdk@17

   # Windows
   # Download from https://adoptium.net/
   ```

### Build Steps

```bash
# 1. Clone the repository
git clone https://github.com/Domusgpt/synth-vib3-plus.git
cd synth-vib3-plus

# 2. Checkout the desired branch
git checkout claude/refactor-synthesizer-visualizer-012K7EbKVyBNNLXNfXwUgF3r

# 3. Get dependencies
flutter pub get

# 4. Verify setup (optional but recommended)
flutter doctor -v

# 5. Build release APK
flutter build apk --release

# 6. Find your APK
# Location: build/app/outputs/flutter-apk/app-release.apk
```

### Build Options

**Release Build** (optimized, smaller size):
```bash
flutter build apk --release
```

**Debug Build** (for development, larger size):
```bash
flutter build apk --debug
```

**Profile Build** (for performance testing):
```bash
flutter build apk --profile
```

**Split APKs by architecture** (smaller individual files):
```bash
flutter build apk --release --split-per-abi
# Creates separate APKs for arm64-v8a, armeabi-v7a, x86_64
```

## Option 3: Build App Bundle (for Play Store)

If you plan to publish to Google Play Store:

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

## Troubleshooting

### Flutter Doctor Issues

**Android SDK not found:**
```bash
flutter config --android-sdk /path/to/android-sdk
```

**Android licenses not accepted:**
```bash
flutter doctor --android-licenses
```

### Build Errors

**Gradle build failed:**
```bash
# Clean build artifacts
flutter clean

# Re-fetch dependencies
flutter pub get

# Try building again
flutter build apk --release
```

**Out of memory during build:**
```bash
# Edit android/gradle.properties and add:
org.gradle.jvmargs=-Xmx4096m -XX:MaxPermSize=512m
```

**SSL/Certificate errors:**
```bash
# Update Flutter
flutter upgrade

# Clear Flutter cache
flutter pub cache repair
```

### Firebase Configuration

The app uses Firebase for cloud sync. If you encounter Firebase errors:

1. **For testing only**: Disable Firebase by commenting out Firebase initialization in `lib/main.dart`
2. **For full functionality**: Set up your own Firebase project:
   - Create project at https://console.firebase.google.com
   - Add Android app with package name: `com.clearseas.synther_vib34d_holographic`
   - Download `google-services.json` to `android/app/`
   - Rebuild the app

## Installation on Android Device

### Via USB (ADB)

```bash
# Connect device via USB with USB debugging enabled
flutter install

# Or use adb directly
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Direct Installation

1. Transfer the APK to your device (email, cloud storage, etc.)
2. Enable "Install from Unknown Sources" in Settings
3. Open the APK file and tap "Install"

## Testing

After installation, refer to `DEVICE_TESTING_GUIDE.md` for comprehensive testing procedures.

## APK Size Optimization

Current release APK size: ~50-80 MB (typical for Flutter apps with WebView)

To reduce size:

1. **Split by ABI**: `flutter build apk --split-per-abi` (~20-30 MB per architecture)
2. **Use App Bundle**: For Play Store automatic optimization
3. **Remove unused assets**: Check `assets/` directory
4. **Enable ProGuard**: For code minification (already enabled in release builds)

## GitHub Actions Details

The workflow (`.github/workflows/build-apk.yml`) automatically:

- Sets up Flutter 3.38.1
- Installs dependencies
- Runs code analysis (non-blocking)
- Runs tests (non-blocking)
- Builds release APK
- Uploads APK as workflow artifact (30-day retention)
- Creates pre-release with APK attachment (for claude/* branches)

## Signing Configuration

Currently using debug signing for development. For production release:

1. Create a keystore:
   ```bash
   keytool -genkey -v -keystore ~/synth-vib3-plus-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias synth-vib3-plus
   ```

2. Create `android/key.properties`:
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=synth-vib3-plus
   storeFile=/path/to/synth-vib3-plus-key.jks
   ```

3. Update `android/app/build.gradle.kts` to use the keystore

## Next Steps

After building:

1. Install on physical Android device (required - audio doesn't work on emulators)
2. Follow the testing guide in `DEVICE_TESTING_GUIDE.md`
3. Report any issues with system health output from the app

---

For questions or issues, contact Paul Phillips at Paul@clearseassolutions.com

© 2025 Paul Phillips - Clear Seas Solutions LLC
