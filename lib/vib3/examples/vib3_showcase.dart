/**
 * VIB3+ Showcase Example
 *
 * A complete demonstration of the VIB3+ native 4D visualization system.
 * Shows all three visual systems with interactive controls.
 *
 * Usage:
 * ```dart
 * Navigator.push(context, MaterialPageRoute(
 *   builder: (_) => const VIB3ShowcaseScreen(),
 * ));
 * ```
 *
 * A Paul Phillips Manifestation
 * © 2025 Paul Phillips - Clear Seas Solutions LLC
 */

import 'package:flutter/material.dart';
import '../vib3.dart';

/// Complete showcase screen for VIB3+ visualization
class VIB3ShowcaseScreen extends StatefulWidget {
  const VIB3ShowcaseScreen({super.key});

  @override
  State<VIB3ShowcaseScreen> createState() => _VIB3ShowcaseScreenState();
}

class _VIB3ShowcaseScreenState extends State<VIB3ShowcaseScreen> {
  VisualSystem _currentSystem = VisualSystem.quantum;
  int _geometryIndex = 0;
  double _hueShift = 200.0;
  double _glowIntensity = 1.0;
  double _autoRotateSpeed = 0.3;
  bool _demoMode = true;
  double _audioReactivity = 0.5;

  final List<String> _systemNames = ['Quantum', 'Holographic', 'Faceted'];
  final List<String> _geometryNames = [
    'Tetrahedron', 'Hypercube', 'Sphere', 'Torus',
    'Klein Bottle', 'Fractal', 'Wave', 'Crystal',
  ];
  final List<String> _coreNames = ['Base', 'Hypersphere', 'Hypertetrahedron'];

  String get _currentGeometryName {
    final baseIndex = _geometryIndex % 8;
    final coreIndex = _geometryIndex ~/ 8;
    return '${_coreNames[coreIndex]} ${_geometryNames[baseIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // VIB3+ Visualization
          Positioned.fill(
            child: VIB3Widget(
              system: _currentSystem,
              geometryIndex: _geometryIndex,
              hueShift: _hueShift,
              glowIntensity: _glowIntensity,
              autoRotateSpeed: _autoRotateSpeed,
              demoMode: _demoMode,
              audioReactivityStrength: _audioReactivity,
              enableInteraction: true,
            ),
          ),

          // Controls overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildControls(),
          ),

          // Info overlay
          Positioned(
            left: 16,
            top: MediaQuery.of(context).padding.top + 16,
            child: _buildInfoPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'VIB3+ Native',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _systemNames[_currentSystem.index],
            style: TextStyle(
              color: _getSystemColor(),
              fontSize: 14,
            ),
          ),
          Text(
            _currentGeometryName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Text(
            'Geometry ${_geometryIndex + 1}/24',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSystemColor() {
    switch (_currentSystem) {
      case VisualSystem.quantum:
        return Colors.cyan;
      case VisualSystem.holographic:
        return Colors.purple;
      case VisualSystem.faceted:
        return Colors.teal;
    }
  }

  Widget _buildControls() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black87,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // System selector
          _buildSystemSelector(),
          const SizedBox(height: 16),

          // Geometry navigator
          _buildGeometryNavigator(),
          const SizedBox(height: 16),

          // Sliders
          _buildSliders(),
        ],
      ),
    );
  }

  Widget _buildSystemSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: VisualSystem.values.map((system) {
        final isSelected = _currentSystem == system;
        return GestureDetector(
          onTap: () => setState(() => _currentSystem = system),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _getSystemColor() : Colors.white12,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white24,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              _systemNames[system.index],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGeometryNavigator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous, color: Colors.white),
          onPressed: () => setState(() {
            _geometryIndex = (_geometryIndex - 1 + 24) % 24;
          }),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => _showGeometryPicker(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              _currentGeometryName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.skip_next, color: Colors.white),
          onPressed: () => setState(() {
            _geometryIndex = (_geometryIndex + 1) % 24;
          }),
        ),
      ],
    );
  }

  Widget _buildSliders() {
    return Column(
      children: [
        // Hue shift
        _buildSlider(
          label: 'Hue',
          value: _hueShift,
          min: 0,
          max: 360,
          color: HSLColor.fromAHSL(1, _hueShift, 0.8, 0.5).toColor(),
          onChanged: (v) => setState(() => _hueShift = v),
        ),

        // Glow intensity
        _buildSlider(
          label: 'Glow',
          value: _glowIntensity,
          min: 0,
          max: 3,
          color: Colors.amber,
          onChanged: (v) => setState(() => _glowIntensity = v),
        ),

        // Rotation speed
        _buildSlider(
          label: 'Speed',
          value: _autoRotateSpeed,
          min: 0,
          max: 1,
          color: Colors.blue,
          onChanged: (v) => setState(() => _autoRotateSpeed = v),
        ),

        // Audio reactivity
        Row(
          children: [
            Expanded(
              child: _buildSlider(
                label: 'Audio',
                value: _audioReactivity,
                min: 0,
                max: 1,
                color: Colors.green,
                onChanged: (v) => setState(() => _audioReactivity = v),
              ),
            ),
            Switch(
              value: _demoMode,
              onChanged: (v) => setState(() => _demoMode = v),
              activeColor: Colors.green,
            ),
            const SizedBox(width: 8),
            Text(
              'Demo',
              style: TextStyle(
                color: _demoMode ? Colors.green : Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.3),
              thumbColor: color,
              overlayColor: color.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            value.toStringAsFixed(1),
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ),
      ],
    );
  }

  void _showGeometryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (context) => _GeometryPicker(
        currentIndex: _geometryIndex,
        onSelect: (index) {
          setState(() => _geometryIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _GeometryPicker extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _GeometryPicker({
    required this.currentIndex,
    required this.onSelect,
  });

  static const _geometryNames = [
    'Tetrahedron', 'Hypercube', 'Sphere', 'Torus',
    'Klein Bottle', 'Fractal', 'Wave', 'Crystal',
  ];

  static const _coreNames = ['Base', 'Hypersphere', 'Hypertetrahedron'];
  static const _coreColors = [Colors.cyan, Colors.purple, Colors.amber];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Geometry',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          for (int core = 0; core < 3; core++) ...[
            Text(
              _coreNames[core],
              style: TextStyle(
                color: _coreColors[core],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(8, (base) {
                final index = core * 8 + base;
                final isSelected = index == currentIndex;
                return GestureDetector(
                  onTap: () => onSelect(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _coreColors[core]
                          : Colors.white12,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.white24,
                      ),
                    ),
                    child: Text(
                      _geometryNames[base],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

/// Simple full-screen VIB3+ demo widget
class VIB3DemoWidget extends StatelessWidget {
  final VisualSystem system;
  final int geometryIndex;

  const VIB3DemoWidget({
    super.key,
    this.system = VisualSystem.quantum,
    this.geometryIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: VIB3Widget(
        system: system,
        geometryIndex: geometryIndex,
        demoMode: true,
        enableInteraction: true,
      ),
    );
  }
}
