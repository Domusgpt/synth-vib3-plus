#!/bin/bash
# Synth-VIB3+ Test Runner
# Runs tests locally and optionally on Firebase Test Lab

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Synth-VIB3+ Test Runner${NC}"
echo -e "${GREEN}========================================${NC}"

# Check for Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: Flutter not found in PATH${NC}"
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Get Flutter version
echo -e "\n${YELLOW}Flutter version:${NC}"
flutter --version

# Function to run unit tests
run_unit_tests() {
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}  Running Unit Tests${NC}"
    echo -e "${GREEN}========================================${NC}"
    flutter test --reporter expanded
}

# Function to run synthesis test (pure Dart)
run_synthesis_test() {
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}  Running Synthesis Branch Test${NC}"
    echo -e "${GREEN}========================================${NC}"
    dart test_synthesis.dart
}

# Function to build debug APK
build_debug_apk() {
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}  Building Debug APK${NC}"
    echo -e "${GREEN}========================================${NC}"
    flutter build apk --debug
    echo -e "${GREEN}APK built at: build/app/outputs/flutter-apk/app-debug.apk${NC}"
}

# Function to build instrumented test APK
build_test_apk() {
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}  Building Test APK for Firebase Test Lab${NC}"
    echo -e "${GREEN}========================================${NC}"

    # Build the app APK
    flutter build apk --debug

    # Build the instrumentation test APK
    pushd android
    ./gradlew app:assembleDebugAndroidTest
    popd

    echo -e "${GREEN}Test APKs built:${NC}"
    echo "  App: build/app/outputs/flutter-apk/app-debug.apk"
    echo "  Test: build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
}

# Function to run on Firebase Test Lab
run_firebase_test_lab() {
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}  Running on Firebase Test Lab${NC}"
    echo -e "${GREEN}========================================${NC}"

    # Check for gcloud
    if ! command -v gcloud &> /dev/null; then
        echo -e "${RED}Error: gcloud CLI not found${NC}"
        echo "Please install: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi

    # Check if APKs exist
    APP_APK="build/app/outputs/flutter-apk/app-debug.apk"
    TEST_APK="build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"

    if [[ ! -f "$APP_APK" ]] || [[ ! -f "$TEST_APK" ]]; then
        echo -e "${YELLOW}Building test APKs first...${NC}"
        build_test_apk
    fi

    # Run on Firebase Test Lab
    echo -e "${YELLOW}Running instrumentation tests on Pixel 6...${NC}"
    gcloud firebase test android run \
        --type instrumentation \
        --app "$APP_APK" \
        --test "$TEST_APK" \
        --device model=oriole,version=33,locale=en,orientation=portrait \
        --timeout 10m \
        --results-bucket gs://synth-vib3-test-results \
        --results-dir "$(date +%Y%m%d_%H%M%S)"
}

# Function to run quick local test on connected device
run_device_test() {
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}  Running Integration Test on Device${NC}"
    echo -e "${GREEN}========================================${NC}"

    # Check for connected device
    if ! flutter devices | grep -q "android"; then
        echo -e "${RED}Error: No Android device connected${NC}"
        echo "Please connect a device or start an emulator"
        exit 1
    fi

    flutter test integration_test/audio_playback_test.dart --reporter expanded
}

# Parse command line arguments
case "${1:-all}" in
    unit)
        run_unit_tests
        ;;
    synthesis)
        run_synthesis_test
        ;;
    build)
        build_debug_apk
        ;;
    build-test)
        build_test_apk
        ;;
    firebase)
        run_firebase_test_lab
        ;;
    device)
        run_device_test
        ;;
    all)
        run_synthesis_test
        run_unit_tests
        build_debug_apk
        ;;
    *)
        echo "Usage: $0 {unit|synthesis|build|build-test|firebase|device|all}"
        echo ""
        echo "Commands:"
        echo "  unit       - Run Flutter unit tests"
        echo "  synthesis  - Run synthesis branch test (pure Dart)"
        echo "  build      - Build debug APK"
        echo "  build-test - Build APKs for Firebase Test Lab"
        echo "  firebase   - Run tests on Firebase Test Lab"
        echo "  device     - Run integration test on connected device"
        echo "  all        - Run synthesis test, unit tests, and build APK"
        exit 1
        ;;
esac

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Test run complete!${NC}"
echo -e "${GREEN}========================================${NC}"
