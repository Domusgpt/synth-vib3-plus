// Synthesizer Engine
//
// Core audio synthesis system with bidirectional parameter coupling
// to VIB34D visual parameters. Supports:
// - Dual oscillator system with frequency modulation
// - Multi-mode filter (lowpass, highpass, bandpass)
// - Wavetable oscillators with morphing capability
// - Effects processor (reverb, delay)
// - Real-time parameter modulation from visual system
//
// A Paul Phillips Manifestation
//
import 'dart:math' as math;
import 'dart:typed_data';

/// Waveform types for oscillators
enum Waveform {
  sine,
  sawtooth,
  square,
  triangle,
  wavetable,
}

/// Filter types
enum FilterType {
  lowpass,
  highpass,
  bandpass,
  notch,
}

/// ADSR Envelope
class Envelope {
  double attack = 0.01;  // seconds
  double decay = 0.1;    // seconds
  double sustain = 0.7;  // level (0-1)
  double release = 0.3;  // seconds

  Envelope({
    this.attack = 0.01,
    this.decay = 0.1,
    this.sustain = 0.7,
    this.release = 0.3,
  });
}

/// Main synthesizer engine
class SynthesizerEngine {
  // Audio configuration
  final double sampleRate;
  final int bufferSize;

  // Oscillators
  late final Oscillator oscillator1;
  late final Oscillator oscillator2;

  // Filter
  late final Filter filter;

  // Envelope
  late final Envelope envelope;

  // Effects
  late final Reverb reverb;
  late final Delay delay;

  // Master parameters
  double masterVolume = 0.7;
  double mixBalance = 0.5; // 0 = osc1 only, 1 = osc2 only

  // Modulation inputs (from visual system)
  double _osc1FreqModulation = 0.0;  // ±2 semitones
  double _osc2FreqModulation = 0.0;  // ±2 semitones
  double _filterCutoffModulation = 0.0; // ±40%
  double _wavetablePositionModulation = 0.0; // 0-1
  int voiceCount = 1; // Make public instead of private

  SynthesizerEngine({
    this.sampleRate = 44100.0,
    this.bufferSize = 512,
  }) {
    oscillator1 = Oscillator(
      sampleRate: sampleRate,
      waveform: Waveform.sawtooth,
    );

    oscillator2 = Oscillator(
      sampleRate: sampleRate,
      waveform: Waveform.square,
    );

    filter = Filter(
      sampleRate: sampleRate,
      type: FilterType.lowpass,
    );

    envelope = Envelope();

    reverb = Reverb(sampleRate: sampleRate);
    delay = Delay(sampleRate: sampleRate);
  }

  /// Generate audio buffer
  Float32List generateBuffer(int frames) {
    final buffer = Float32List(frames);

    for (int i = 0; i < frames; i++) {
      // Apply frequency modulation from visual system
      oscillator1.frequencyModulation = _osc1FreqModulation;
      oscillator2.frequencyModulation = _osc2FreqModulation;

      // Generate oscillator outputs
      final osc1Sample = oscillator1.nextSample();
      final osc2Sample = oscillator2.nextSample();

      // Mix oscillators
      final mixed = (osc1Sample * (1.0 - mixBalance)) + (osc2Sample * mixBalance);

      // Apply filter with modulation
      filter.cutoffModulation = _filterCutoffModulation;
      final filtered = filter.process(mixed);

      // Apply effects
      final delayed = delay.process(filtered);
      final reverberated = reverb.process(delayed);

      // Master output
      buffer[i] = (reverberated * masterVolume).clamp(-1.0, 1.0);
    }

    return buffer;
  }

  /// Set base note (MIDI note number)
  void setNote(int midiNote) {
    final freq = _midiToFrequency(midiNote);
    oscillator1.baseFrequency = freq;
    oscillator2.baseFrequency = freq;
  }

  /// Modulate oscillator 1 frequency (±2 semitones from visual system)
  void modulateOscillator1Frequency(double semitones) {
    _osc1FreqModulation = semitones.clamp(-2.0, 2.0);
  }

  /// Modulate oscillator 2 frequency (±2 semitones from visual system)
  void modulateOscillator2Frequency(double semitones) {
    _osc2FreqModulation = semitones.clamp(-2.0, 2.0);
  }

  /// Modulate filter cutoff (±40% from visual system)
  void modulateFilterCutoff(double amount) {
    _filterCutoffModulation = amount.clamp(0.0, 0.8); // 0-80% range
  }

  /// Set wavetable position (from visual morph parameter)
  void setWavetablePosition(double position) {
    _wavetablePositionModulation = position.clamp(0.0, 1.0);
    oscillator1.wavetablePosition = _wavetablePositionModulation;
    oscillator2.wavetablePosition = _wavetablePositionModulation;
  }

  /// Set voice count (from visual vertex count)
  void setVoiceCount(int count) {
    voiceCount = count.clamp(1, 16);
  }

  /// Set reverb mix (from visual projection distance)
  void setReverbMix(double mix) {
    reverb.mix = mix.clamp(0.0, 1.0);
  }

  /// Set delay time (from visual layer depth)
  void setDelayTime(double milliseconds) {
    delay.delayTime = milliseconds.clamp(0.0, 1000.0);
  }

  /// Convert MIDI note to frequency
  double _midiToFrequency(int midiNote) {
    return 440.0 * math.pow(2.0, (midiNote - 69) / 12.0);
  }
}

/// Oscillator with frequency modulation support
class Oscillator {
  final double sampleRate;
  Waveform waveform;

  double baseFrequency = 440.0;
  double frequencyModulation = 0.0; // ±2 semitones
  double detune = 0.0; // ±100 cents (alias for frequencyModulation in smaller range)
  double phase = 0.0;
  double wavetablePosition = 0.0;

  Oscillator({
    required this.sampleRate,
    required this.waveform,
  });

  /// Generate next sample
  double nextSample() {
    // Apply frequency modulation and detune (cents to frequency ratio)
    final totalModulation = frequencyModulation + (detune / 100.0);
    final freqRatio = math.pow(2.0, totalModulation / 12.0);
    final modulatedFreq = baseFrequency * freqRatio;

    // Generate sample based on waveform
    final sample = _generateWaveform(phase);

    // Advance phase
    phase += (2.0 * math.pi * modulatedFreq) / sampleRate;
    if (phase >= 2.0 * math.pi) {
      phase -= 2.0 * math.pi;
    }

    return sample;
  }

  /// Generate waveform sample at current phase
  double _generateWaveform(double ph) {
    switch (waveform) {
      case Waveform.sine:
        return math.sin(ph);

      case Waveform.sawtooth:
        return 2.0 * (ph / (2.0 * math.pi)) - 1.0;

      case Waveform.square:
        return ph < math.pi ? 1.0 : -1.0;

      case Waveform.triangle:
        final t = ph / (2.0 * math.pi);
        return t < 0.5 ? (4.0 * t - 1.0) : (3.0 - 4.0 * t);

      case Waveform.wavetable:
        // Simple wavetable: morph between sine and sawtooth
        final sine = math.sin(ph);
        final saw = 2.0 * (ph / (2.0 * math.pi)) - 1.0;
        return sine * (1.0 - wavetablePosition) + saw * wavetablePosition;
    }
  }
}

/// Multi-mode filter with resonance
class Filter {
  final double sampleRate;
  FilterType type;

  double baseCutoff = 1000.0; // Hz
  double cutoffModulation = 0.0; // 0-0.8 (±40%)
  double resonance = 0.7;
  double envelopeAmount = 0.0; // 0-1 (envelope modulation depth)

  // State variables
  double _z1 = 0.0;
  double _z2 = 0.0;

  Filter({
    required this.sampleRate,
    required this.type,
  });

  /// Process sample through filter
  double process(double input) {
    // Apply cutoff modulation
    final modulatedCutoff = baseCutoff * (1.0 + cutoffModulation);
    final normalizedCutoff = (2.0 * modulatedCutoff / sampleRate).clamp(0.01, 0.99);

    // Simple 2-pole filter
    final f = 2.0 * math.sin(math.pi * normalizedCutoff);
    final q = resonance;

    double output;

    switch (type) {
      case FilterType.lowpass:
        _z1 += f * (input - _z1 + q * (_z1 - _z2));
        _z2 += f * (_z1 - _z2);
        output = _z2;
        break;

      case FilterType.highpass:
        _z1 += f * (input - _z1 + q * (_z1 - _z2));
        _z2 += f * (_z1 - _z2);
        output = input - _z2;
        break;

      case FilterType.bandpass:
        _z1 += f * (input - _z1 + q * (_z1 - _z2));
        _z2 += f * (_z1 - _z2);
        output = _z1 - _z2;
        break;

      case FilterType.notch:
        _z1 += f * (input - _z1 + q * (_z1 - _z2));
        _z2 += f * (_z1 - _z2);
        output = input - (_z1 - _z2);
        break;
    }

    return output.clamp(-1.0, 1.0);
  }
}

/// Simple reverb effect
class Reverb {
  final double sampleRate;

  double mix = 0.3; // Wet/dry mix (0-1)
  double roomSize = 0.7;
  double damping = 0.5;

  // Delay lines for reverb
  late final List<double> _buffer;
  final int _bufferSize;
  int _writePos = 0;

  Reverb({required this.sampleRate})
      : _bufferSize = (sampleRate * 0.1).round() {
    _buffer = List<double>.filled(_bufferSize, 0.0);
  }

  /// Process sample through reverb
  double process(double input) {
    // Read from delay buffer
    final delayed = _buffer[_writePos];

    // Apply feedback
    final feedback = delayed * roomSize * (1.0 - damping);

    // Write to buffer
    _buffer[_writePos] = input + feedback;

    // Advance write position
    _writePos = (_writePos + 1) % _bufferSize;

    // Mix dry and wet signals
    return input * (1.0 - mix) + delayed * mix;
  }
}

/// Simple delay effect
class Delay {
  final double sampleRate;

  double delayTime = 250.0; // milliseconds
  double time = 250.0; // milliseconds (alias for delayTime)
  double feedback = 0.4;
  double mix = 0.3;

  late final List<double> _buffer;
  final int _maxBufferSize;
  int _writePos = 0;

  Delay({required this.sampleRate})
      : _maxBufferSize = (sampleRate * 2.0).round() {
    _buffer = List<double>.filled(_maxBufferSize, 0.0);
  }

  /// Process sample through delay
  double process(double input) {
    // Sync time with delayTime
    time = delayTime;

    // Calculate read position based on delay time
    final delaySamples = (delayTime * sampleRate / 1000.0).round();
    final readPos = (_writePos - delaySamples) % _maxBufferSize;

    // Read delayed sample
    final delayed = _buffer[readPos < 0 ? readPos + _maxBufferSize : readPos];

    // Write to buffer with feedback
    _buffer[_writePos] = input + delayed * feedback;

    // Advance write position
    _writePos = (_writePos + 1) % _maxBufferSize;

    // Mix dry and wet signals
    return input * (1.0 - mix) + delayed * mix;
  }
}
