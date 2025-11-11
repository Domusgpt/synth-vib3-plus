#version 300 es

/**
 * VIB34D RGB Chromatic Aberration Shader
 *
 * Separates RGB channels based on Stereo Width:
 * - Wider stereo = more chromatic aberration
 * - Creates holographic "reality distortion" effect
 *
 * A Paul Phillips Manifestation
 */

precision highp float;

uniform sampler2D u_sceneTexture;
uniform float u_splitAmount;    // Controlled by stereo width parameter
uniform vec2 u_resolution;

in vec2 v_texCoord;
out vec4 fragColor;

void main() {
    vec2 texelSize = 1.0 / u_resolution;

    // Calculate radial offset from center
    vec2 centerOffset = v_texCoord - 0.5;
    float distanceFromCenter = length(centerOffset);

    // Radial split: stronger at edges
    vec2 splitDirection = normalize(centerOffset);
    vec2 offset = splitDirection * texelSize * u_splitAmount * (1.0 + distanceFromCenter);

    // Sample RGB channels at different offsets
    float r = texture(u_sceneTexture, v_texCoord + offset).r;
    float g = texture(u_sceneTexture, v_texCoord).g;
    float b = texture(u_sceneTexture, v_texCoord - offset).b;

    fragColor = vec4(r, g, b, 1.0);
}
