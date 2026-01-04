# Experimental Shader Systems

These are standalone shader function prototypes for potential future visual systems.
They follow the same 5-layer architecture as the core systems but are not yet integrated.

## Files

- `nebula.glsl` - Cosmic deep space (Hubble telescope, stellar nurseries)
- `neural.glsl` - Bio-digital synaptic (brain scans, bioluminescence)
- `plasma.glsl` - Fusion energy (tokamak reactor, ball lightning)

## Integration Notes

To add these to the main shader:
1. Add to VisualSystem enum in `lib/vib3/core/vib3_engine.dart`
2. Add SoundFamily definitions in `lib/synthesis/synthesis_branch_manager.dart`
3. Add ModulationConfig factories in `lib/vib3/audio/audio_reactive_modulator.dart`
4. Update switch statements in `lib/vib3/widget/vib3_widget.dart`
5. Update `_systemToFloat()` in `lib/vib3/rendering/vib3_shader_renderer.dart`
6. Paste render function into `shaders/vib3_core.frag`
7. Update main() system selection

## Warning

These shaders contain FOR LOOPS that must be UNROLLED for mobile GPU compatibility.
