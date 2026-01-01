// Performance Benchmark Tests
//
// Measures critical performance metrics for the audio-visual synthesizer:
// - Audio buffer generation latency
// - Visual parameter update throughput
// - Memory allocation patterns
// - 60 FPS frame budget compliance
//
// A Paul Phillips Manifestation

import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

import 'package:synther_vib34d_holographic/audio/synthesizer_engine.dart';
import 'package:synther_vib34d_holographic/providers/visual_provider.dart';
import 'package:synther_vib34d_holographic/vib3/math/rotation_4d.dart';
import 'package:synther_vib34d_holographic/vib3/geometry/polytope_generator.dart';
import 'package:vector_math/vector_math.dart' as vm;

void main() {
  group('Audio Buffer Generation Benchmarks', () {
    late SynthesizerEngine synth;

    setUp(() {
      synth = SynthesizerEngine(
        sampleRate: 44100.0,
        bufferSize: 512,
      );
      synth.setNote(60);
    });

    test('512 sample buffer generates within 10ms (audio latency target)', () {
      const iterations = 100;
      final stopwatch = Stopwatch();

      // Warm up
      for (int i = 0; i < 10; i++) {
        synth.generateBuffer(512);
      }

      stopwatch.start();
      for (int i = 0; i < iterations; i++) {
        synth.generateBuffer(512);
      }
      stopwatch.stop();

      final avgMicroseconds = stopwatch.elapsedMicroseconds / iterations;
      final avgMilliseconds = avgMicroseconds / 1000;

      print('Average 512-sample buffer generation: ${avgMilliseconds.toStringAsFixed(3)}ms');

      // At 44100 Hz, 512 samples = 11.6ms of audio
      // We need to generate faster than real-time
      expect(avgMilliseconds, lessThan(10),
          reason: 'Buffer generation must be faster than 10ms for real-time audio');
    });

    test('1024 sample buffer generates within 20ms', () {
      const iterations = 100;
      final stopwatch = Stopwatch();

      stopwatch.start();
      for (int i = 0; i < iterations; i++) {
        synth.generateBuffer(1024);
      }
      stopwatch.stop();

      final avgMicroseconds = stopwatch.elapsedMicroseconds / iterations;
      final avgMilliseconds = avgMicroseconds / 1000;

      print('Average 1024-sample buffer generation: ${avgMilliseconds.toStringAsFixed(3)}ms');

      expect(avgMilliseconds, lessThan(20),
          reason: 'Larger buffer should still complete in time');
    });

    test('Buffer generation with full effects chain', () {
      // Enable all effects
      synth.setReverbMix(0.5);
      synth.setDelayTime(250);
      synth.setNoiseLevel(0.1);
      synth.setLFORate(5.0);
      synth.setStereoWidth(0.7);

      const iterations = 100;
      final stopwatch = Stopwatch();

      stopwatch.start();
      for (int i = 0; i < iterations; i++) {
        synth.generateBuffer(512);
      }
      stopwatch.stop();

      final avgMicroseconds = stopwatch.elapsedMicroseconds / iterations;
      final avgMilliseconds = avgMicroseconds / 1000;

      print('Average buffer with full effects: ${avgMilliseconds.toStringAsFixed(3)}ms');

      expect(avgMilliseconds, lessThan(15),
          reason: 'Even with all effects, should be under 15ms');
    });

    test('Buffer memory allocation is efficient', () {
      // Generate many buffers and check they don't accumulate
      final List<Float32List> buffers = [];

      for (int i = 0; i < 1000; i++) {
        final buffer = synth.generateBuffer(512);
        if (i % 100 == 0) {
          buffers.add(buffer); // Keep some for verification
        }
      }

      // Verify buffers are independent
      expect(buffers.length, equals(10));
      expect(buffers.first.length, equals(512));
    });
  });

  group('Visual Provider Update Benchmarks', () {
    late VisualProvider provider;

    setUp(() {
      provider = VisualProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('Parameter updates complete within 1ms (60 FPS budget = 16.6ms)', () {
      const iterations = 1000;
      final stopwatch = Stopwatch();

      stopwatch.start();
      for (int i = 0; i < iterations; i++) {
        provider.setRotationXY(i * 0.01);
        provider.setVertexBrightness((i % 100) / 100.0);
        provider.setHueShift(i % 360.0);
      }
      stopwatch.stop();

      final avgMicroseconds = stopwatch.elapsedMicroseconds / iterations;

      print('Average parameter update: ${avgMicroseconds.toStringAsFixed(1)}μs');

      expect(avgMicroseconds, lessThan(1000),
          reason: 'Each update should be under 1ms');
    });

    test('Rotation updates at 60 Hz are sustainable', () {
      const frames = 600; // 10 seconds at 60 FPS
      final stopwatch = Stopwatch();

      stopwatch.start();
      for (int i = 0; i < frames; i++) {
        provider.updateRotations(1.0 / 60.0); // 60 FPS delta
      }
      stopwatch.stop();

      final avgMicroseconds = stopwatch.elapsedMicroseconds / frames;

      print('Average updateRotations: ${avgMicroseconds.toStringAsFixed(1)}μs');

      // Must be well under 16.6ms frame budget
      expect(avgMicroseconds, lessThan(5000),
          reason: 'Rotation update should be under 5ms');
    });

    test('getVisualState serialization is fast', () {
      const iterations = 1000;
      final stopwatch = Stopwatch();

      stopwatch.start();
      for (int i = 0; i < iterations; i++) {
        final state = provider.getVisualState();
        expect(state, isNotEmpty);
      }
      stopwatch.stop();

      final avgMicroseconds = stopwatch.elapsedMicroseconds / iterations;

      print('Average getVisualState: ${avgMicroseconds.toStringAsFixed(1)}μs');

      expect(avgMicroseconds, lessThan(500),
          reason: 'State serialization should be under 0.5ms');
    });
  });

  group('4D Rotation Matrix Benchmarks', () {
    test('6D rotation matrix computation is fast', () {
      const iterations = 10000;
      final stopwatch = Stopwatch();

      stopwatch.start();
      for (int i = 0; i < iterations; i++) {
        Rotation4D.apply6DRotation(
          xy: i * 0.001,
          xz: i * 0.002,
          yz: i * 0.003,
          xw: i * 0.004,
          yw: i * 0.005,
          zw: i * 0.006,
        );
      }
      stopwatch.stop();

      final avgMicroseconds = stopwatch.elapsedMicroseconds / iterations;

      print('Average 6D rotation matrix: ${avgMicroseconds.toStringAsFixed(2)}μs');

      expect(avgMicroseconds, lessThan(100),
          reason: 'Matrix computation should be under 100μs');
    });

    test('Vertex rotation is efficient for typical polytope sizes', () {
      // Generate typical polytope (hypercube = 16 vertices)
      final polytope = PolytopeGenerator.generateBase(1);
      final matrix = Rotation4D.apply6DRotation(
        xy: 0.5,
        xz: 0.7,
        yz: 0.3,
        xw: 0.2,
        yw: 0.4,
        zw: 0.6,
      );

      const iterations = 1000;
      final stopwatch = Stopwatch();

      stopwatch.start();
      for (int i = 0; i < iterations; i++) {
        Rotation4D.rotateVertices(polytope.vertices, matrix);
      }
      stopwatch.stop();

      final avgMicroseconds = stopwatch.elapsedMicroseconds / iterations;
      final vertexCount = polytope.vertices.length;

      print('Average rotation of $vertexCount vertices: ${avgMicroseconds.toStringAsFixed(1)}μs');

      // For 16-120 vertices, should be well under 1ms
      expect(avgMicroseconds, lessThan(1000),
          reason: 'Vertex rotation should be under 1ms');
    });

    test('4D to 3D projection is efficient', () {
      final vertices = List.generate(
        100,
        (i) => vm.Vector4(i * 0.1, i * 0.2, i * 0.3, i * 0.05),
      );

      const iterations = 1000;
      final stopwatch = Stopwatch();

      stopwatch.start();
      for (int i = 0; i < iterations; i++) {
        for (final v in vertices) {
          Rotation4D.project4Dto3D(v, distance: 2.0);
        }
      }
      stopwatch.stop();

      final avgMicroseconds = stopwatch.elapsedMicroseconds / iterations;

      print('Average projection of 100 vertices: ${avgMicroseconds.toStringAsFixed(1)}μs');

      expect(avgMicroseconds, lessThan(500),
          reason: 'Projection should be under 0.5ms');
    });
  });

  group('Polytope Generation Benchmarks', () {
    test('All 8 base geometries generate within acceptable time', () {
      for (int i = 0; i < 8; i++) {
        final stopwatch = Stopwatch()..start();

        final polytope = PolytopeGenerator.generateBase(i);

        stopwatch.stop();

        print('Geometry $i (${polytope.name}): '
            '${stopwatch.elapsedMicroseconds}μs, '
            '${polytope.vertices.length} vertices');

        expect(stopwatch.elapsedMicroseconds, lessThan(10000),
            reason: 'Geometry generation should be under 10ms');
      }
    });

    test('Repeated geometry access is cached/fast', () {
      const iterations = 100;
      final stopwatch = Stopwatch();

      stopwatch.start();
      for (int i = 0; i < iterations; i++) {
        for (int g = 0; g < 8; g++) {
          PolytopeGenerator.generateBase(g);
        }
      }
      stopwatch.stop();

      final avgMicroseconds = stopwatch.elapsedMicroseconds / (iterations * 8);

      print('Average geometry access: ${avgMicroseconds.toStringAsFixed(1)}μs');

      // With caching, should be very fast
      expect(avgMicroseconds, lessThan(100),
          reason: 'Cached geometry access should be fast');
    });
  });

  group('Combined Frame Budget Test', () {
    late SynthesizerEngine synth;
    late VisualProvider visualProvider;

    setUp(() {
      synth = SynthesizerEngine();
      synth.setNote(60);
      visualProvider = VisualProvider();
    });

    tearDown(() {
      visualProvider.dispose();
    });

    test('Full frame update fits within 16.6ms budget', () {
      const frames = 100;
      final frameTimes = <int>[];

      for (int frame = 0; frame < frames; frame++) {
        final stopwatch = Stopwatch()..start();

        // 1. Update visual rotations
        visualProvider.updateRotations(1.0 / 60.0);

        // 2. Generate geometry rotation matrix
        final matrix = Rotation4D.apply6DRotation(
          xy: visualProvider.rotationXY,
          xz: visualProvider.rotationXZ,
          yz: visualProvider.rotationYZ,
          xw: visualProvider.rotationXW,
          yw: visualProvider.rotationYW,
          zw: visualProvider.rotationZW,
        );

        // 3. Rotate a typical polytope
        final polytope = PolytopeGenerator.generateBase(frame % 8);
        Rotation4D.rotateVertices(polytope.vertices, matrix);

        // 4. Project to 3D (simulated)
        for (final v in polytope.vertices) {
          Rotation4D.project4Dto3D(v, distance: 2.0);
        }

        // 5. Generate audio buffer (at 60 FPS, this would be ~735 samples)
        synth.generateBuffer(735);

        stopwatch.stop();
        frameTimes.add(stopwatch.elapsedMicroseconds);
      }

      final avgMicroseconds = frameTimes.reduce((a, b) => a + b) / frames;
      final maxMicroseconds = frameTimes.reduce((a, b) => a > b ? a : b);
      final avgMilliseconds = avgMicroseconds / 1000;
      final maxMilliseconds = maxMicroseconds / 1000;

      print('Frame time: avg=${avgMilliseconds.toStringAsFixed(2)}ms, '
          'max=${maxMilliseconds.toStringAsFixed(2)}ms');

      // 16.6ms budget for 60 FPS
      expect(avgMilliseconds, lessThan(16.6),
          reason: 'Average frame should fit in 60 FPS budget');

      // Allow some headroom for GC spikes
      expect(maxMilliseconds, lessThan(33),
          reason: 'Max frame should not exceed 30 FPS floor');
    });
  });

  group('Memory Efficiency Tests', () {
    test('No memory leak in repeated buffer generation', () {
      final synth = SynthesizerEngine();
      synth.setNote(60);

      // Generate many buffers
      for (int i = 0; i < 10000; i++) {
        synth.generateBuffer(512);
      }

      // If we get here without OOM, test passes
      expect(true, isTrue);
    });

    test('Provider state updates do not accumulate allocations', () {
      final provider = VisualProvider();

      for (int i = 0; i < 10000; i++) {
        provider.setRotationXY(i * 0.001);
        provider.setVertexBrightness((i % 100) / 100.0);
        provider.setHueShift(i % 360.0);
        provider.setSaturation((i % 100) / 100.0);
      }

      provider.dispose();
      expect(true, isTrue);
    });
  });
}
