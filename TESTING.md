# Synth-VIB3+ Testing Guide

## Overview

This project includes comprehensive testing infrastructure:
- **Flutter Unit Tests**: Test individual components (providers, managers)
- **Flutter Widget Tests**: Test UI components
- **Flutter Integration Tests**: Test full app flow
- **Playwright E2E Tests**: Test deployed web application

## Running Tests

### Quick Start

```bash
# Install dependencies
flutter pub get
npm install

# Run all Flutter tests
flutter test

# Run Playwright E2E tests (against deployed site)
npm test

# Run specific test types
./scripts/run_tests.sh unit        # Unit tests only
./scripts/run_tests.sh e2e         # Playwright only
./scripts/run_tests.sh analyze     # Static analysis
```

### Flutter Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart
flutter test test/unit/visual_provider_test.dart
flutter test test/unit/synthesis_branch_manager_test.dart

# Run with verbose output
flutter test --reporter expanded
```

### Playwright E2E Tests

```bash
# Run all E2E tests
npm test

# Run with UI (interactive mode)
npm run test:ui

# Run with browser visible
npm run test:headed

# Debug mode
npm run test:debug

# View last test report
npm run test:report
```

### Integration Tests

Integration tests require a connected device/emulator:

```bash
# List available devices
flutter devices

# Run on specific device
flutter test integration_test/app_test.dart -d <device_id>

# Run on Chrome (web)
flutter test integration_test/app_test.dart -d chrome
```

## Test Configuration

### Playwright

The Playwright configuration (`playwright.config.ts`) targets:
- Default: `https://domusgpt.github.io/synth-vib3-plus/`
- Custom URL: `TEST_URL=http://localhost:8080 npm test`

### Test Projects

- **Mobile Chrome**: Tests mobile viewport (412x915)
- **Desktop Chrome**: Tests desktop viewport (1280x720)

## Test Coverage

### Unit Tests Cover

- **VisualProvider**
  - System switching (Quantum, Faceted, Holographic)
  - Geometry index calculation (0-23)
  - 4D rotation management
  - Parameter normalization
  - Velocity calculation

- **SynthesisBranchManager**
  - Geometry to core mapping (Base/Hypersphere/Hypertetrahedron)
  - Base geometry extraction (8 types)
  - Visual system to sound family mapping
  - Audio buffer generation
  - Envelope behavior

### Architecture Validation

Tests verify the 3D Matrix System:
- 3 Visual Systems × 24 Geometries = 72 unique combinations
- Core index formula: `geometry ~/ 8`
- Base geometry formula: `geometry % 8`
- Inverse formula: `(core * 8) + base`

### E2E Tests Cover

- App initialization
- VIB3+ visualizer initialization (black screen detection)
- Visual system switching
- Geometry panel functionality
- Synthesis panel controls
- XY Pad interaction
- Audio context availability
- Responsive layout (portrait/landscape/tablet)
- Performance (frame rate)

## Test Files

```
test/
├── widget_test.dart                        # Main widget tests
└── unit/
    ├── visual_provider_test.dart           # VisualProvider tests
    └── synthesis_branch_manager_test.dart  # SynthesisBranchManager tests

integration_test/
└── app_test.dart                           # Full app integration tests

e2e/
└── app.spec.ts                             # Playwright E2E tests
```

## CI/CD Integration

For GitHub Actions, add this workflow:

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  flutter-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
      - run: flutter analyze

  playwright-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: npm test
```

## Troubleshooting

### Flutter tests fail to import

Ensure you've run `flutter pub get` to install dependencies.

### Playwright tests can't connect

Check the TEST_URL environment variable:
```bash
TEST_URL=http://localhost:8080 npm test
```

### WebGL tests fail

Playwright uses software rendering by default. The tests account for this.

### Integration tests hang

Integration tests require a connected device. Use:
```bash
flutter devices  # List available devices
flutter test integration_test/app_test.dart -d <device_id>
```

---

A Paul Phillips Manifestation
