#version 300 es

/**
 * VIB34D 4D Polytope Fragment Shader
 *
 * Audio-reactive coloring based on:
 * - W-coordinate (4th dimension) → Base hue
 * - Spectral Centroid → Hue shift
 * - Frequency Band Energy → Brightness
 * - RMS Amplitude → Glow intensity
 *
 * A Paul Phillips Manifestation
 */

precision highp float;

// Inputs from vertex shader
in vec3 v_position3d;
in float v_wCoord;
in vec3 v_normal;

// Uniforms (controlled by audio analysis)
uniform float u_time;
uniform float u_glowIntensity;      // Controlled by RMS amplitude
uniform float u_hueShift;           // Controlled by spectral centroid (0-360°)
uniform float u_brightness;         // Controlled by frequency band energy

// Output
out vec4 fragColor;

// HSV to RGB conversion
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
    // Base hue from W-coordinate (-1 to +1 → 0 to 0.5 hue range)
    float baseHue = (v_wCoord + 1.0) * 0.25;

    // Apply audio-reactive hue shift
    float finalHue = fract(baseHue + u_hueShift / 360.0);

    // Saturation: high for vibrant holographic effect
    float saturation = 0.85;

    // Value: base brightness modulated by audio
    float value = u_brightness;

    // Convert HSV to RGB
    vec3 baseColor = hsv2rgb(vec3(finalHue, saturation, value));

    // Add pulsing glow effect synchronized with audio
    float glowPulse = 1.0 + u_glowIntensity * (1.0 + 0.3 * sin(u_time * 3.14159));

    // Simple directional lighting based on normal
    vec3 lightDir = normalize(vec3(0.5, 0.5, 1.0));
    float diffuse = max(dot(v_normal, lightDir), 0.0) * 0.5 + 0.5;

    // Combine lighting and glow
    vec3 finalColor = baseColor * diffuse * glowPulse;

    fragColor = vec4(finalColor, 1.0);
}
