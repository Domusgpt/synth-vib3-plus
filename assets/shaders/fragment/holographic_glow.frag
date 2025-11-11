#version 300 es

/**
 * VIB34D Holographic Glow Post-Processing Shader
 *
 * Bloom effect controlled by Filter Resonance (Q factor):
 * - Higher resonance = more intense glow
 * - Creates holographic depth through multi-pass sampling
 *
 * A Paul Phillips Manifestation
 */

precision highp float;

uniform sampler2D u_sceneTexture;
uniform float u_glowIntensity;  // Controlled by filter resonance
uniform vec2 u_resolution;

in vec2 v_texCoord;
out vec4 fragColor;

void main() {
    vec4 scene = texture(u_sceneTexture, v_texCoord);

    // Multi-pass bloom: sample surrounding pixels with Gaussian-like weights
    vec2 texelSize = 1.0 / u_resolution;
    vec4 bloom = vec4(0.0);

    // 9-tap kernel
    const float weights[9] = float[](
        0.0625, 0.125, 0.0625,
        0.125,  0.25,  0.125,
        0.0625, 0.125, 0.0625
    );

    int index = 0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 offset = vec2(float(x), float(y)) * texelSize * 3.0;
            bloom += texture(u_sceneTexture, v_texCoord + offset) * weights[index];
            index++;
        }
    }

    // Combine scene + bloom with audio-reactive intensity
    vec3 finalColor = scene.rgb + bloom.rgb * u_glowIntensity * 2.0;

    fragColor = vec4(finalColor, 1.0);
}
