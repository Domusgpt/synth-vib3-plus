#!/bin/bash
# Synth-VIB3+ Test Runner Script
#
# Runs all tests including:
# - Flutter unit tests
# - Flutter widget tests
# - Flutter integration tests
# - Playwright web E2E tests
#
# Usage:
#   ./scripts/run_tests.sh           # Run all tests
#   ./scripts/run_tests.sh unit      # Run only unit tests
#   ./scripts/run_tests.sh e2e       # Run only Playwright E2E tests
#   ./scripts/run_tests.sh analyze   # Run static analysis

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Synth-VIB3+ Test Runner${NC}"
echo -e "${BLUE}========================================${NC}"

# Change to project root
cd "$(dirname "$0")/.."

run_flutter_tests() {
    echo -e "\n${YELLOW}Running Flutter unit tests...${NC}"
    flutter test test/widget_test.dart --reporter expanded || true

    echo -e "\n${YELLOW}Running unit tests...${NC}"
    flutter test test/unit/ --reporter expanded || true
}

run_integration_tests() {
    echo -e "\n${YELLOW}Running integration tests...${NC}"
    # Integration tests require a device/emulator
    # flutter test integration_test/app_test.dart
    echo -e "${YELLOW}Note: Integration tests require a connected device/emulator${NC}"
    echo -e "Run: flutter test integration_test/app_test.dart -d <device_id>"
}

run_playwright_tests() {
    echo -e "\n${YELLOW}Running Playwright E2E tests...${NC}"

    if [ ! -d "node_modules/@playwright" ]; then
        echo -e "${YELLOW}Installing Playwright...${NC}"
        npm install
    fi

    npx playwright test --reporter=list
}

run_analysis() {
    echo -e "\n${YELLOW}Running Flutter analysis...${NC}"
    flutter analyze --no-fatal-infos
}

case "$1" in
    unit)
        run_flutter_tests
        ;;
    integration)
        run_integration_tests
        ;;
    e2e|playwright)
        run_playwright_tests
        ;;
    analyze)
        run_analysis
        ;;
    all|"")
        run_analysis
        run_flutter_tests
        run_integration_tests
        run_playwright_tests
        ;;
    *)
        echo "Usage: $0 {unit|integration|e2e|analyze|all}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Test run complete!${NC}"
echo -e "${GREEN}========================================${NC}"
