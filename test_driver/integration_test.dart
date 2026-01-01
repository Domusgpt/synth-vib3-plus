// Integration Test Driver
//
// Required for Firebase Test Lab integration.
// This driver allows Flutter integration tests to run as
// Android instrumentation tests on Firebase Test Lab.
//
// Usage:
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/app_test.dart
//
// A Paul Phillips Manifestation

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
