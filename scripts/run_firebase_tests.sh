#!/bin/bash
# Firebase Test Lab Runner Script
#
# Builds and runs integration tests on Firebase Test Lab
# across a matrix of Android devices.
#
# Prerequisites:
# - Firebase CLI installed (firebase-tools)
# - gcloud CLI installed and configured
# - Firebase project linked
#
# A Paul Phillips Manifestation

set -e

# Configuration
PROJECT_ID="${FIREBASE_PROJECT_ID:-synth-vib3-plus}"
RESULTS_BUCKET="${RESULTS_BUCKET:-gs://synth-vib3-test-results}"
RESULTS_DIR="test-results-$(date +%Y%m%d-%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Synth-VIB3+ Firebase Test Lab Runner ===${NC}"
echo ""

# Step 1: Build the debug APK
echo -e "${YELLOW}Building debug APK...${NC}"
flutter build apk --debug

# Step 2: Build the instrumentation test APK
echo -e "${YELLOW}Building instrumentation test APK...${NC}"
pushd android
./gradlew app:assembleAndroidTest
./gradlew app:assembleDebug -Ptarget=integration_test/app_test.dart
popd

# APK paths
APP_APK="build/app/outputs/apk/debug/app-debug.apk"
TEST_APK="build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"

# Verify APKs exist
if [ ! -f "$APP_APK" ]; then
    echo -e "${RED}Error: App APK not found at $APP_APK${NC}"
    exit 1
fi

if [ ! -f "$TEST_APK" ]; then
    echo -e "${RED}Error: Test APK not found at $TEST_APK${NC}"
    exit 1
fi

echo -e "${GREEN}APKs built successfully${NC}"
echo "  App: $APP_APK"
echo "  Test: $TEST_APK"

# Step 3: Upload to Firebase Test Lab
echo ""
echo -e "${YELLOW}Uploading to Firebase Test Lab...${NC}"

# Device matrix - targeting key Android versions and screen sizes
# Phone devices
PHONE_DEVICES=(
    "model=oriole,version=33"          # Pixel 6, Android 13
    "model=redfin,version=30"          # Pixel 5, Android 11
    "model=blueline,version=28"        # Pixel 3, Android 9
    "model=a]12,version=31"            # Samsung Galaxy A12
)

# Tablet devices
TABLET_DEVICES=(
    "model=griffin,version=25"         # Tab S3, Android 7
)

# Build device args
DEVICE_ARGS=""
for device in "${PHONE_DEVICES[@]}"; do
    DEVICE_ARGS="$DEVICE_ARGS --device $device"
done

# Run tests on Firebase Test Lab
echo -e "${YELLOW}Running instrumentation tests...${NC}"
gcloud firebase test android run \
    --type instrumentation \
    --app "$APP_APK" \
    --test "$TEST_APK" \
    $DEVICE_ARGS \
    --results-bucket "$RESULTS_BUCKET" \
    --results-dir "$RESULTS_DIR" \
    --timeout 30m \
    --no-record-video \
    --no-performance-metrics \
    --project "$PROJECT_ID"

echo ""
echo -e "${GREEN}=== Test Complete ===${NC}"
echo "Results: $RESULTS_BUCKET/$RESULTS_DIR"
echo ""

# Step 4: Download and display results summary
echo -e "${YELLOW}Downloading results...${NC}"
gsutil -m cp -r "$RESULTS_BUCKET/$RESULTS_DIR" ./test-results/

# Parse results
if [ -f "./test-results/$RESULTS_DIR/test_result_1.xml" ]; then
    echo ""
    echo -e "${GREEN}Test Results Summary:${NC}"
    grep -E "(testsuite|testcase)" "./test-results/$RESULTS_DIR/test_result_1.xml" | head -20
fi

echo ""
echo -e "${GREEN}Done!${NC}"
