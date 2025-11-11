/**
 * Synther-VIB34D Holographic Main Application
 *
 * Professional holographic synthesizer with 4D visualization
 * and bidirectional audio-visual coupling.
 *
 * A Paul Phillips Manifestation
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/audio_provider.dart';
import 'providers/visual_provider.dart';
import 'mapping/parameter_bridge.dart';
import 'visual/vib34d_widget.dart';
import 'models/mapping_preset.dart';
import 'audio/synthesizer_engine.dart';

void main() {
  runApp(const SyntherVIB34DApp());
}

class SyntherVIB34DApp extends StatelessWidget {
  const SyntherVIB34DApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => VisualProvider()),
        ChangeNotifierProxyProvider2<AudioProvider, VisualProvider, ParameterBridge>(
          create: (context) => ParameterBridge(
            audioProvider: context.read<AudioProvider>(),
            visualProvider: context.read<VisualProvider>(),
          ),
          update: (context, audio, visual, previous) => previous ?? ParameterBridge(
            audioProvider: audio,
            visualProvider: visual,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Synther-VIB34D Holographic',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          primaryColor: Colors.cyan,
          colorScheme: ColorScheme.dark(
            primary: Colors.cyan,
            secondary: Colors.purple,
            surface: const Color(0xFF1A1A1A),
          ),
        ),
        home: const MainPerformanceScreen(),
      ),
    );
  }
}

class MainPerformanceScreen extends StatefulWidget {
  const MainPerformanceScreen({Key? key}) : super(key: key);

  @override
  State<MainPerformanceScreen> createState() => _MainPerformanceScreenState();
}

class _MainPerformanceScreenState extends State<MainPerformanceScreen> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();

    // Start parameter bridge after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bridge = context.read<ParameterBridge>();
      bridge.start();
      debugPrint('✅ Parameter bridge started at 60 FPS');
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final visualProvider = context.watch<VisualProvider>();
    final bridge = context.watch<ParameterBridge>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        title: Row(
          children: [
            const Icon(Icons.music_note, color: Colors.cyan),
            const SizedBox(width: 10),
            const Text(
              'Synther-VIB34D',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${bridge.currentFPS.toStringAsFixed(1)} FPS',
              style: TextStyle(
                color: bridge.currentFPS > 55 ? Colors.green : Colors.orange,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showControls ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            tooltip: 'Toggle Controls',
          ),
        ],
      ),
      body: Column(
        children: [
          // VIB34D Visualization Display
          Expanded(
            flex: _showControls ? 3 : 5,
            child: Container(
              color: Colors.black,
              child: VIB34DWidget(
                visualProvider: visualProvider,
                audioProvider: audioProvider,
              ),
            ),
          ),

          // Controls Panel
          if (_showControls)
            Expanded(
              flex: 2,
              child: Container(
                color: const Color(0xFF1A1A1A),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // VIB34D System Switcher
                      _buildSectionHeader('VIB34D System'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSystemButton(
                              context,
                              'Quantum',
                              visualProvider.currentSystem == 'quantum',
                              () => visualProvider.switchSystem('quantum'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildSystemButton(
                              context,
                              'Holographic',
                              visualProvider.currentSystem == 'holographic',
                              () => visualProvider.switchSystem('holographic'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildSystemButton(
                              context,
                              'Faceted',
                              visualProvider.currentSystem == 'faceted',
                              () => visualProvider.switchSystem('faceted'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Bidirectional Coupling Controls
                      _buildSectionHeader('Coupling Mode'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildToggleButton(
                              'Audio → Visual',
                              bridge.currentPreset.audioReactiveEnabled,
                              (value) => bridge.setAudioReactive(value),
                              Icons.graphic_eq,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildToggleButton(
                              'Visual → Audio',
                              bridge.currentPreset.visualReactiveEnabled,
                              (value) => bridge.setVisualReactive(value),
                              Icons.threed_rotation,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Audio Test Buttons
                      _buildSectionHeader('Audio Test'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAudioTestButton(
                              context,
                              'C4 (Middle C)',
                              Colors.blue,
                              () => audioProvider.playNote(60),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildAudioTestButton(
                              context,
                              'E4',
                              Colors.green,
                              () => audioProvider.playNote(64),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildAudioTestButton(
                              context,
                              'G4',
                              Colors.purple,
                              () => audioProvider.playNote(67),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => audioProvider.stopNote(),
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop Audio'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[900],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Synthesizer Controls
                      _buildSectionHeader('Synthesizer'),
                      const SizedBox(height: 10),

                      // Oscillator 1 & 2 Waveform
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Osc 1', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 4),
                                _buildWaveformSelector(context, audioProvider, 1),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Osc 2', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 4),
                                _buildWaveformSelector(context, audioProvider, 2),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Filter Controls
                      const Text('Filter', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      _buildFilterTypeSelector(context, audioProvider),
                      const SizedBox(height: 10),

                      _buildSlider(
                        'Cutoff',
                        audioProvider.synth.filter.baseCutoff / 20000.0,
                        (value) => audioProvider.setFilterCutoff(value * 20000.0),
                        Icons.tune,
                      ),
                      _buildSlider(
                        'Resonance',
                        audioProvider.synth.filter.resonance / 10.0,
                        (value) => audioProvider.setFilterResonance(value * 10.0),
                        Icons.graphic_eq,
                      ),
                      const SizedBox(height: 10),

                      // Effects Controls
                      const Text('Reverb', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      _buildSlider(
                        'Room Size',
                        audioProvider.synth.reverb.roomSize,
                        (value) => audioProvider.setReverbRoomSize(value),
                        Icons.home,
                      ),
                      _buildSlider(
                        'Damping',
                        audioProvider.synth.reverb.damping,
                        (value) => audioProvider.setReverbDamping(value),
                        Icons.water_drop,
                      ),
                      const SizedBox(height: 10),

                      const Text('Delay', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      _buildSlider(
                        'Feedback',
                        audioProvider.synth.delay.feedback,
                        (value) => audioProvider.setDelayFeedback(value),
                        Icons.repeat,
                      ),
                      _buildSlider(
                        'Mix',
                        audioProvider.synth.delay.mix,
                        (value) => audioProvider.setDelayMix(value),
                        Icons.blur_on,
                      ),
                      const SizedBox(height: 10),

                      // Master Volume
                      _buildSlider(
                        'Master Volume',
                        audioProvider.synth.masterVolume,
                        (value) => audioProvider.setMasterVolume(value),
                        Icons.volume_up,
                      ),
                      const SizedBox(height: 20),

                      // Audio Features Display
                      if (audioProvider.currentFeatures != null) ...[
                        _buildSectionHeader('Audio Analysis'),
                        const SizedBox(height: 10),
                        _buildAudioFeatureBar(
                          'Bass',
                          audioProvider.getBassEnergy(),
                          Colors.red,
                        ),
                        _buildAudioFeatureBar(
                          'Mid',
                          audioProvider.getMidEnergy(),
                          Colors.green,
                        ),
                        _buildAudioFeatureBar(
                          'High',
                          audioProvider.getHighEnergy(),
                          Colors.blue,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Preset Selector
                      _buildSectionHeader('Mapping Preset'),
                      const SizedBox(height: 10),
                      _buildPresetSelector(context, bridge),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.cyan,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildSystemButton(
    BuildContext context,
    String label,
    bool isActive,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.cyan : Colors.grey[800],
        foregroundColor: isActive ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label),
    );
  }

  Widget _buildToggleButton(
    String label,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: value ? Colors.cyan.withOpacity(0.2) : Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? Colors.cyan : Colors.grey[700]!,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: value ? Colors.cyan : Colors.grey[500],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: value ? Colors.cyan : Colors.grey[500],
                      fontWeight: value ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: Colors.cyan,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioTestButton(
    BuildContext context,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.3),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildAudioFeatureBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            child: Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelector(BuildContext context, ParameterBridge bridge) {
    final presets = [
      MappingPreset.defaultPreset(),
      MappingPreset.bassHeavy(),
      MappingPreset.ambientSpatial(),
    ];

    // Use String for dropdown value to avoid object comparison issues
    return DropdownButton<String>(
      value: bridge.currentPreset.name,
      isExpanded: true,
      dropdownColor: Colors.grey[900],
      items: presets.map((preset) {
        return DropdownMenuItem<String>(
          value: preset.name,
          child: Text(
            preset.name,
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: (presetName) {
        if (presetName != null) {
          // Find preset by name
          final preset = presets.firstWhere((p) => p.name == presetName);
          bridge.loadPreset(preset);
        }
      },
    );
  }

  Widget _buildWaveformSelector(BuildContext context, AudioProvider audio, int oscNum) {
    final currentWaveform = oscNum == 1
        ? audio.synth.oscillator1.waveform
        : audio.synth.oscillator2.waveform;

    return DropdownButton<Waveform>(
      value: currentWaveform,
      isExpanded: true,
      dropdownColor: Colors.grey[900],
      items: Waveform.values.map((waveform) {
        return DropdownMenuItem<Waveform>(
          value: waveform,
          child: Text(
            waveform.name.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      }).toList(),
      onChanged: (waveform) {
        if (waveform != null) {
          if (oscNum == 1) {
            audio.setOscillator1Waveform(waveform);
          } else {
            audio.setOscillator2Waveform(waveform);
          }
        }
      },
    );
  }

  Widget _buildFilterTypeSelector(BuildContext context, AudioProvider audio) {
    return DropdownButton<FilterType>(
      value: audio.synth.filter.type,
      isExpanded: true,
      dropdownColor: Colors.grey[900],
      items: FilterType.values.map((type) {
        return DropdownMenuItem<FilterType>(
          value: type,
          child: Text(
            type.name.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      }).toList(),
      onChanged: (type) {
        if (type != null) {
          audio.setFilterType(type);
        }
      },
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    Function(double) onChanged,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyan, size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(0.0, 1.0),
              onChanged: onChanged,
              activeColor: Colors.cyan,
              inactiveColor: Colors.grey[800],
            ),
          ),
          SizedBox(
            width: 35,
            child: Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    context.read<ParameterBridge>().stop();
    super.dispose();
  }
}
