#!/bin/bash
# Synth-VIB3+ Development Environment Setup
# A Paul Phillips Manifestation

set -e  # Exit on error

echo "🎵 Synth-VIB3+ Development Setup"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Flutter installation
echo "Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed${NC}"
    echo "Please install Flutter from https://docs.flutter.dev/get-started/install"
    exit 1
else
    echo -e "${GREEN}✅ Flutter installed${NC}"
    flutter --version
fi

# Check Dart installation
echo ""
echo "Checking Dart installation..."
if ! command -v dart &> /dev/null; then
    echo -e "${RED}❌ Dart is not installed${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Dart installed${NC}"
    dart --version
fi

# Check Java installation (for Android builds)
echo ""
echo "Checking Java installation..."
if ! command -v java &> /dev/null; then
    echo -e "${YELLOW}⚠️  Java is not installed (required for Android builds)${NC}"
    echo "Install Java 17: https://adoptium.net/"
else
    echo -e "${GREEN}✅ Java installed${NC}"
    java -version 2>&1 | head -n 1
fi

# Run flutter doctor
echo ""
echo "Running Flutter doctor..."
flutter doctor

# Get dependencies
echo ""
echo "Installing Flutter dependencies..."
flutter pub get

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Dependencies installed successfully${NC}"
else
    echo -e "${RED}❌ Failed to install dependencies${NC}"
    exit 1
fi

# Run code generation (if needed)
echo ""
echo "Checking for code generation..."
if grep -q "build_runner" pubspec.yaml; then
    echo "Running code generation..."
    flutter pub run build_runner build --delete-conflicting-outputs
else
    echo "No code generation needed"
fi

# Run analyzer
echo ""
echo "Running static analysis..."
flutter analyze --no-fatal-infos

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ No analysis issues${NC}"
else
    echo -e "${YELLOW}⚠️  Analysis found issues (see above)${NC}"
fi

# Run tests
echo ""
echo "Running tests..."
flutter test

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed${NC}"
else
    echo -e "${RED}❌ Some tests failed${NC}"
fi

# Format code
echo ""
echo "Formatting code..."
dart format .

# Check for connected devices
echo ""
echo "Checking for connected devices..."
flutter devices

# Setup complete
echo ""
echo "=================================="
echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Connect an Android device or start an emulator"
echo "2. Run 'flutter run' to launch the app"
echo "3. Read DEVELOPMENT.md for workflow guidelines"
echo "4. Check PROJECT_STATUS.md for current implementation status"
echo ""
echo "Recommended VS Code extensions:"
echo "- Press Ctrl+Shift+P and select 'Extensions: Show Recommended Extensions'"
echo ""
echo "Happy coding! 🎨🎵"
echo ""
echo "A Paul Phillips Manifestation"
echo "Paul@clearseassolutions.com"
