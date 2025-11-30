// Synth Patch Model
//
// Represents a complete synthesizer configuration that can be
// saved, loaded, and recalled.
//
// A Paul Phillips Manifestation
//
import '../audio/synthesizer_engine.dart';

class SynthPatch {
  final String name;
  final String description;

  // Oscillator 1 settings
  final Waveform oscillator1Waveform;
  final int oscillator1Octave;
  final double oscillator1Detune; // cents

  // Oscillator 2 settings
  final Waveform oscillator2Waveform;
  final int oscillator2Octave;
  final double oscillator2Detune;

  // Mix
  final double mixBalance; // 0 = osc1, 1 = osc2

  // Filter settings
  final FilterType filterType;
  final double filterCutoff; // Hz
  final double filterResonance; // 0-1

  // Reverb settings
  final double reverbMix;
  final double reverbRoomSize;
  final double reverbDamping;

  // Delay settings
  final double delayTime; // ms
  final double delayFeedback;
  final double delayMix;

  // Master
  final double masterVolume;

  const SynthPatch({
    required this.name,
    required this.description,
    required this.oscillator1Waveform,
    required this.oscillator1Octave,
    required this.oscillator1Detune,
    required this.oscillator2Waveform,
    required this.oscillator2Octave,
    required this.oscillator2Detune,
    required this.mixBalance,
    required this.filterType,
    required this.filterCutoff,
    required this.filterResonance,
    required this.reverbMix,
    required this.reverbRoomSize,
    required this.reverbDamping,
    required this.delayTime,
    required this.delayFeedback,
    required this.delayMix,
    required this.masterVolume,
  });

  /// Default patch
  factory SynthPatch.defaultPatch() {
    return const SynthPatch(
      name: 'Default',
      description: 'Basic sawtooth + square patch',
      oscillator1Waveform: Waveform.sawtooth,
      oscillator1Octave: 0,
      oscillator1Detune: 0.0,
      oscillator2Waveform: Waveform.square,
      oscillator2Octave: 0,
      oscillator2Detune: 5.0,
      mixBalance: 0.5,
      filterType: FilterType.lowpass,
      filterCutoff: 1000.0,
      filterResonance: 0.7,
      reverbMix: 0.3,
      reverbRoomSize: 0.7,
      reverbDamping: 0.5,
      delayTime: 250.0,
      delayFeedback: 0.4,
      delayMix: 0.3,
      masterVolume: 0.7,
    );
  }

  /// Bass patch
  factory SynthPatch.bass() {
    return const SynthPatch(
      name: 'Bass Heavy',
      description: 'Deep bass with sub oscillator',
      oscillator1Waveform: Waveform.sawtooth,
      oscillator1Octave: -1,
      oscillator1Detune: 0.0,
      oscillator2Waveform: Waveform.square,
      oscillator2Octave: -2,
      oscillator2Detune: 0.0,
      mixBalance: 0.6,
      filterType: FilterType.lowpass,
      filterCutoff: 200.0,
      filterResonance: 0.8,
      reverbMix: 0.1,
      reverbRoomSize: 0.3,
      reverbDamping: 0.7,
      delayTime: 0.0,
      delayFeedback: 0.0,
      delayMix: 0.0,
      masterVolume: 0.8,
    );
  }

  /// Ambient pad
  factory SynthPatch.ambientPad() {
    return const SynthPatch(
      name: 'Ambient Pad',
      description: 'Lush ambient pad with reverb',
      oscillator1Waveform: Waveform.sine,
      oscillator1Octave: 0,
      oscillator1Detune: 0.0,
      oscillator2Waveform: Waveform.triangle,
      oscillator2Octave: 1,
      oscillator2Detune: 10.0,
      mixBalance: 0.5,
      filterType: FilterType.lowpass,
      filterCutoff: 2000.0,
      filterResonance: 0.3,
      reverbMix: 0.7,
      reverbRoomSize: 0.9,
      reverbDamping: 0.3,
      delayTime: 500.0,
      delayFeedback: 0.6,
      delayMix: 0.4,
      masterVolume: 0.6,
    );
  }

  /// Lead synth
  factory SynthPatch.lead() {
    return const SynthPatch(
      name: 'Lead Synth',
      description: 'Bright lead with wavetable',
      oscillator1Waveform: Waveform.wavetable,
      oscillator1Octave: 0,
      oscillator1Detune: -5.0,
      oscillator2Waveform: Waveform.wavetable,
      oscillator2Octave: 0,
      oscillator2Detune: 5.0,
      mixBalance: 0.5,
      filterType: FilterType.bandpass,
      filterCutoff: 3000.0,
      filterResonance: 0.6,
      reverbMix: 0.4,
      reverbRoomSize: 0.5,
      reverbDamping: 0.4,
      delayTime: 125.0,
      delayFeedback: 0.3,
      delayMix: 0.2,
      masterVolume: 0.7,
    );
  }

  /// Apply patch to synthesizer engine
  void applyToSynthesizer(SynthesizerEngine synth) {
    // Oscillator 1
    synth.oscillator1.waveform = oscillator1Waveform;
    synth.oscillator1.baseFrequency *= _octaveToFreqRatio(oscillator1Octave);
    // Detune would require additional implementation

    // Oscillator 2
    synth.oscillator2.waveform = oscillator2Waveform;
    synth.oscillator2.baseFrequency *= _octaveToFreqRatio(oscillator2Octave);

    // Mix
    synth.mixBalance = mixBalance;

    // Filter
    synth.filter.type = filterType;
    synth.filter.baseCutoff = filterCutoff;
    synth.filter.resonance = filterResonance;

    // Reverb
    synth.reverb.mix = reverbMix;
    synth.reverb.roomSize = reverbRoomSize;
    synth.reverb.damping = reverbDamping;

    // Delay
    synth.delay.delayTime = delayTime;
    synth.delay.feedback = delayFeedback;
    synth.delay.mix = delayMix;

    // Master
    synth.masterVolume = masterVolume;
  }

  double _octaveToFreqRatio(int octave) {
    return 1.0; // Simplified - full implementation would use pow(2, octave)
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'oscillator1Waveform': oscillator1Waveform.toString(),
      'oscillator1Octave': oscillator1Octave,
      'oscillator1Detune': oscillator1Detune,
      'oscillator2Waveform': oscillator2Waveform.toString(),
      'oscillator2Octave': oscillator2Octave,
      'oscillator2Detune': oscillator2Detune,
      'mixBalance': mixBalance,
      'filterType': filterType.toString(),
      'filterCutoff': filterCutoff,
      'filterResonance': filterResonance,
      'reverbMix': reverbMix,
      'reverbRoomSize': reverbRoomSize,
      'reverbDamping': reverbDamping,
      'delayTime': delayTime,
      'delayFeedback': delayFeedback,
      'delayMix': delayMix,
      'masterVolume': masterVolume,
    };
  }

  /// Create from JSON
  factory SynthPatch.fromJson(Map<String, dynamic> json) {
    return SynthPatch(
      name: json['name'] as String,
      description: json['description'] as String,
      oscillator1Waveform: _parseWaveform(json['oscillator1Waveform'] as String),
      oscillator1Octave: json['oscillator1Octave'] as int,
      oscillator1Detune: (json['oscillator1Detune'] as num).toDouble(),
      oscillator2Waveform: _parseWaveform(json['oscillator2Waveform'] as String),
      oscillator2Octave: json['oscillator2Octave'] as int,
      oscillator2Detune: (json['oscillator2Detune'] as num).toDouble(),
      mixBalance: (json['mixBalance'] as num).toDouble(),
      filterType: _parseFilterType(json['filterType'] as String),
      filterCutoff: (json['filterCutoff'] as num).toDouble(),
      filterResonance: (json['filterResonance'] as num).toDouble(),
      reverbMix: (json['reverbMix'] as num).toDouble(),
      reverbRoomSize: (json['reverbRoomSize'] as num).toDouble(),
      reverbDamping: (json['reverbDamping'] as num).toDouble(),
      delayTime: (json['delayTime'] as num).toDouble(),
      delayFeedback: (json['delayFeedback'] as num).toDouble(),
      delayMix: (json['delayMix'] as num).toDouble(),
      masterVolume: (json['masterVolume'] as num).toDouble(),
    );
  }

  static Waveform _parseWaveform(String str) {
    return Waveform.values.firstWhere(
      (e) => e.toString() == str,
      orElse: () => Waveform.sawtooth,
    );
  }

  static FilterType _parseFilterType(String str) {
    return FilterType.values.firstWhere(
      (e) => e.toString() == str,
      orElse: () => FilterType.lowpass,
    );
  }

  @override
  String toString() {
    return 'SynthPatch($name: $description)';
  }
}
