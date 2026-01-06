/**
 * VIB3+ Native 4D Visualization Library
 *
 * A complete native Dart implementation of the VIB3+ 4D holographic
 * visualization system. No WebView required - pure Flutter rendering.
 *
 * ## Features
 *
 * - **Three Visual Systems**: Quantum, Holographic, and Faceted
 * - **24 Geometries**: 8 base polytopes × 3 synthesis cores
 * - **6D Rotation**: Full 4D rotation control (XY, XZ, YZ, XW, YW, ZW)
 * - **Audio Reactivity**: FFT-driven visual modulation
 * - **Post-Processing**: Glow, chromatic aberration, scanlines, etc.
 * - **60 FPS Animation**: Smooth vsync-driven rendering
 * - **Touch Interaction**: Drag to rotate, pinch for 4D effects
 *
 * ## Quick Start
 *
 * ```dart
 * import 'package:synth_vib3_plus/vib3/vib3.dart';
 *
 * // Simple usage with demo mode
 * VIB3Widget(
 *   system: VisualSystem.quantum,
 *   geometryIndex: 0,
 *   demoMode: true,
 * )
 *
 * // With audio reactivity
 * VIB3Widget(
 *   system: VisualSystem.holographic,
 *   geometryIndex: 8,
 *   audioData: yourAudioAnalysis,
 *   audioReactivityStrength: 0.7,
 * )
 *
 * // Using a controller
 * final controller = VIB3Controller();
 * controller.setSystem(VisualSystem.faceted);
 * controller.setGeometry(16);
 *
 * VIB3ControlledWidget(controller: controller)
 * ```
 *
 * ## Geometry System
 *
 * The 24 geometries are organized as:
 * - **Base Geometries (0-7)**: Direct synthesis
 *   - 0: Tetrahedron (5-cell)
 *   - 1: Hypercube (Tesseract)
 *   - 2: Sphere (4D Hypersphere)
 *   - 3: Torus (Clifford Torus)
 *   - 4: Klein Bottle
 *   - 5: Fractal
 *   - 6: Wave
 *   - 7: Crystal (24-cell)
 *
 * - **Hypersphere Core (8-15)**: FM synthesis aesthetic
 *   - Same 8 base geometries with FM modulation styling
 *
 * - **Hypertetrahedron Core (16-23)**: Ring modulation aesthetic
 *   - Same 8 base geometries with ring mod styling
 *
 * A Paul Phillips Manifestation
 * © 2025 Paul Phillips - Clear Seas Solutions LLC
 */

// Core engine
export 'core/vib3_engine.dart';

// Core mathematics
export 'math/quaternion.dart';
export 'math/rotation_4d.dart';

// Geometry system
export 'geometry/geometry_library.dart';
export 'geometry/polytope_generator.dart';

// Rendering
export 'rendering/vib3_native_renderer.dart';
export 'rendering/visual_system_renderer.dart';
export 'rendering/vib3_shader_renderer.dart';

// Post-processing effects
export 'effects/post_processing.dart';

// Audio reactivity
export 'audio/audio_reactive_modulator.dart';

// Widgets
export 'widget/vib3_widget.dart';

// Examples
export 'examples/vib3_showcase.dart';
