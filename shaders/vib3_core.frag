/*
 * VIB3+ Core Fragment Shader - Flutter Native
 *
 * Per-pixel SDF rendering matching VIB3-CORE WebGL quality.
 * 3 visual systems: Quantum, Faceted, Holographic
 * 24 geometries (8 base x 3 cores) with full 6D rotation
 *
 * FLUTTER GLSL COMPLIANCE:
 * - Uses FlutterFragCoord() not gl_FragCoord
 * - No unsigned int or bool types
 * - Handles GLES y-axis inversion
 * - Premultiplied alpha output
 *
 * A Paul Phillips Manifestation
 * (c) 2025 Paul Phillips - Clear Seas Solutions LLC
 */

#include <flutter/runtime_effect.glsl>

// Uniforms - indices must match Dart setFloat() order
uniform vec2 u_resolution;
uniform float u_time;
uniform float u_system;      // 0=Quantum, 1=Faceted, 2=Holographic
uniform float u_geometry;    // 0-23

// 6D Rotation
uniform float u_rotXY;
uniform float u_rotXZ;
uniform float u_rotYZ;
uniform float u_rotXW;
uniform float u_rotYW;
uniform float u_rotZW;

// Visual parameters
uniform float u_hue;
uniform float u_saturation;
uniform float u_brightness;
uniform float u_glowIntensity;
uniform float u_rgbSplit;
uniform float u_morphFactor;
uniform float u_chaos;
uniform float u_gridDensity;

// Audio reactivity
uniform float u_bassEnergy;
uniform float u_midEnergy;
uniform float u_highEnergy;
uniform float u_rmsAmplitude;

out vec4 fragColor;

const float PI = 3.14159265359;

// ============================================================
// UTILITY FUNCTIONS
// ============================================================

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// ============================================================
// 4D ROTATION
// ============================================================

vec4 rotateXY(vec4 p, float a) {
    float c = cos(a), s = sin(a);
    return vec4(p.x*c - p.y*s, p.x*s + p.y*c, p.z, p.w);
}

vec4 rotateXZ(vec4 p, float a) {
    float c = cos(a), s = sin(a);
    return vec4(p.x*c - p.z*s, p.y, p.x*s + p.z*c, p.w);
}

vec4 rotateYZ(vec4 p, float a) {
    float c = cos(a), s = sin(a);
    return vec4(p.x, p.y*c - p.z*s, p.y*s + p.z*c, p.w);
}

vec4 rotateXW(vec4 p, float a) {
    float c = cos(a), s = sin(a);
    return vec4(p.x*c - p.w*s, p.y, p.z, p.x*s + p.w*c);
}

vec4 rotateYW(vec4 p, float a) {
    float c = cos(a), s = sin(a);
    return vec4(p.x, p.y*c - p.w*s, p.z, p.y*s + p.w*c);
}

vec4 rotateZW(vec4 p, float a) {
    float c = cos(a), s = sin(a);
    return vec4(p.x, p.y, p.z*c - p.w*s, p.z*s + p.w*c);
}

vec4 apply6DRotation(vec4 p) {
    p = rotateXY(p, u_rotXY);
    p = rotateXZ(p, u_rotXZ);
    p = rotateYZ(p, u_rotYZ);
    p = rotateXW(p, u_rotXW);
    p = rotateYW(p, u_rotYW);
    p = rotateZW(p, u_rotZW);

    float bassBoost = 1.0 + u_bassEnergy * 0.5;
    float t = u_time * 0.5;
    p = rotateXY(p, t * 0.08 * bassBoost);
    p = rotateXZ(p, t * 0.09 * bassBoost);
    p = rotateYZ(p, t * 0.07);
    p = rotateXW(p, t * 0.10);
    p = rotateYW(p, t * 0.11);
    p = rotateZW(p, t * 0.12);
    return p;
}

// ============================================================
// SDF GEOMETRIES (using float comparisons, no int)
// ============================================================

float sdHypercube(vec4 p) {
    vec4 q = abs(p) - 1.0;
    return length(max(q, 0.0)) + min(max(max(max(q.x, q.y), q.z), q.w), 0.0);
}

float sdSphere(vec4 p) {
    return length(p) - 1.0;
}

float sdTorus(vec4 p) {
    float r1 = 0.8, r2 = 0.3;
    vec2 q = vec2(length(p.xy) - r1, length(p.zw) - r1);
    return length(q) - r2;
}

float sdCrystal(vec4 p) {
    vec4 q = abs(p);
    return max(max(q.x + q.y, q.z + q.w), max(q.x + q.z, q.y + q.w)) - 1.2;
}

float sdTetrahedron(vec4 p) {
    float d = (p.x + p.y + p.z + p.w) * 0.5;
    d = max(d, (-p.x - p.y + p.z + p.w) * 0.5);
    d = max(d, (-p.x + p.y - p.z + p.w) * 0.5);
    d = max(d, (p.x - p.y - p.z + p.w) * 0.5);
    return d - 0.5;
}

float sdWave(vec4 p) {
    float wave = sin(p.x * 3.0 + u_time) * 0.3;
    wave += sin(p.y * 2.0 + u_time * 1.3) * 0.2;
    wave += sin(p.z * 2.5 + u_time * 0.7) * 0.2;
    return length(p) - 0.8 - wave * 0.3;
}

float sdFractal(vec4 p) {
    float d = sdHypercube(p);
    float scale = 1.0;
    for (float i = 0.0; i < 3.0; i += 1.0) {
        vec4 a = mod(p * scale, 2.0) - 1.0;
        scale *= 3.0;
        vec4 r = abs(1.0 - 3.0 * abs(a));
        float c = (min(min(max(r.x, r.y), max(r.y, r.z)), max(r.z, r.w)) - 1.0) / scale;
        d = max(d, c);
    }
    return d;
}

float sdKlein(vec4 p) {
    float r = length(p.xy);
    float theta = atan(p.y, p.x);
    float phi = atan(p.w, p.z);
    float target = 0.8 + 0.3 * sin(theta * 2.0 + phi);
    return abs(r - target) - 0.15;
}

// Get base SDF using float comparison (no int)
float getBaseSDF(vec4 p, float geomIndex) {
    float baseIdx = mod(geomIndex, 8.0);

    // Use step functions for selection (Flutter GLSL compatible)
    float d = sdTetrahedron(p);
    d = mix(d, sdHypercube(p), step(0.5, baseIdx) * step(baseIdx, 1.5));
    d = mix(d, sdSphere(p), step(1.5, baseIdx) * step(baseIdx, 2.5));
    d = mix(d, sdTorus(p), step(2.5, baseIdx) * step(baseIdx, 3.5));
    d = mix(d, sdKlein(p), step(3.5, baseIdx) * step(baseIdx, 4.5));
    d = mix(d, sdFractal(p), step(4.5, baseIdx) * step(baseIdx, 5.5));
    d = mix(d, sdWave(p), step(5.5, baseIdx) * step(baseIdx, 6.5));
    d = mix(d, sdCrystal(p), step(6.5, baseIdx));

    return d;
}

// Apply core modification
float getSDF(vec4 p) {
    float d = getBaseSDF(p, u_geometry);
    float coreIdx = floor(u_geometry / 8.0);
    float len = length(p);

    // FM core (index 1: geometries 8-15)
    float fmMod = sin(d * 10.0 + u_time * 2.0) * 0.1 * (1.0 + u_midEnergy);
    d += fmMod * step(0.5, coreIdx) * step(coreIdx, 1.5);

    // Ring mod core (index 2: geometries 16-23)
    float ringMod = sin(d * 15.0) * cos(len * 8.0) * 0.08 * (1.0 + u_highEnergy);
    d += ringMod * step(1.5, coreIdx);

    // Chaos noise
    d += noise(p.xy * 5.0 + u_time) * u_chaos * 0.1;

    return d;
}

// ============================================================
// VISUAL SYSTEMS
// ============================================================

vec3 renderQuantum(vec2 uv, float d, vec4 p) {
    vec3 color = vec3(0.0);

    // 5 layer rendering with RGB separation
    for (float i = 0.0; i < 5.0; i += 1.0) {
        float layerD = d + i * 0.05;
        float sep = (0.02 + i * 0.07) * (1.0 + u_rmsAmplitude * 0.5);

        float edge = 1.0 - smoothstep(0.0, 0.05 + u_glowIntensity * 0.02, abs(layerD));

        float hueOffset = i * 0.2;
        vec3 layerCol = hsv2rgb(vec3(u_hue/360.0 + hueOffset, 0.85, 0.6 + i * 0.08));

        float rOff = sin(uv.y * 10.0 + u_time + i) * sep;
        float bOff = -sin(uv.y * 10.0 + u_time + i) * sep;

        vec3 separated;
        separated.r = edge * layerCol.r * (1.0 + rOff);
        separated.g = edge * layerCol.g;
        separated.b = edge * layerCol.b * (1.0 + bOff);

        color += separated * (0.3 + i * 0.15);
    }

    float coreGlow = exp(-abs(d) * 3.0) * u_glowIntensity * 0.5;
    color += hsv2rgb(vec3(u_hue/360.0, 0.9, 0.8)) * coreGlow;

    return color * u_brightness;
}

vec3 renderFaceted(vec2 uv, float d, vec4 p) {
    vec3 color = vec3(0.0);

    // Structure layer
    float structHue = (u_hue - 30.0) / 360.0;
    vec3 structCol = hsv2rgb(vec3(structHue, 0.5, 0.25));
    float structEdge = 1.0 - smoothstep(0.0, 0.08, abs(d + 0.02));
    color += structCol * structEdge * 0.5;

    // Fill
    float fill = smoothstep(0.1, 0.0, d) * 0.15;
    color += structCol * fill;

    // Highlight layer
    float highHue = (u_hue + 30.0) / 360.0;
    vec3 highCol = hsv2rgb(vec3(highHue, 0.8 + u_saturation * 0.1, 0.55 + u_brightness * 0.25));
    float edgeW = 0.04 + u_midEnergy * 0.02;
    float highEdge = 1.0 - smoothstep(0.0, edgeW, abs(d));
    color += highCol * highEdge * (0.8 + u_glowIntensity * 0.2);

    // Vertex glow
    float vertGlow = exp(-abs(d) * 8.0) * u_highEnergy * 0.5;
    color += vec3(1.0) * vertGlow;

    return color * u_brightness;
}

vec3 renderHolographic(vec2 uv, float d, vec4 p) {
    vec3 color = vec3(0.0);

    // Multi-layer depth
    for (float layer = 0.0; layer < 5.0; layer += 1.0) {
        float depth = layer / 4.0;
        float layerOff = (layer - 2.0) * 0.08;
        float layerD = d + layerOff + p.w * 0.1 * depth;

        float layerHue = (u_hue + layer * 25.0) / 360.0;
        float layerAlpha = 0.15 + depth * 0.25 + u_rmsAmplitude * 0.15;
        vec3 layerCol = hsv2rgb(vec3(layerHue, 0.7 + u_saturation * 0.2, 0.5 + depth * 0.2));

        float edge = 1.0 - smoothstep(0.0, 0.06 + u_glowIntensity * 0.02, abs(layerD));
        color += layerCol * edge * layerAlpha;
    }

    // Chromatic aberration
    float aberr = u_rgbSplit * 0.01;
    float dist = length(uv);
    color.r *= 1.0 + sin(dist * 10.0 + u_time) * aberr;
    color.g *= 1.0 + sin(dist * 10.0 + u_time + 2.09) * aberr;
    color.b *= 1.0 + sin(dist * 10.0 + u_time + 4.18) * aberr;

    // Holographic shimmer
    float shimmer = sin(uv.x * 50.0 + u_time * 2.0) * sin(uv.y * 50.0 + u_time * 1.5);
    color += vec3(shimmer * 0.05 * u_glowIntensity);

    // Moire
    float moire = sin(dist * u_gridDensity + u_time) * 0.5 + 0.5;
    moire *= sin(dist * u_gridDensity * 1.1 - u_time * 0.5) * 0.5 + 0.5;
    color *= 0.9 + moire * 0.2;

    return color * u_brightness;
}

// ============================================================
// MAIN
// ============================================================

void main() {
    vec2 fragCoord = FlutterFragCoord();

    // Handle OpenGL ES y-axis inversion
    #ifdef IMPELLER_TARGET_OPENGLES
    fragCoord.y = u_resolution.y - fragCoord.y;
    #endif

    vec2 uv = (fragCoord - u_resolution * 0.5) / min(u_resolution.x, u_resolution.y);

    // Create 4D point
    vec4 p = vec4(uv * 2.0, 0.0, 0.0);
    p = apply6DRotation(p);

    // 4D to 3D projection
    float projDist = 2.5;
    float w = projDist / (projDist + p.w);
    p.xyz *= w;

    // Get SDF
    float d = getSDF(p);

    // Background
    float bgHue = u_hue / 360.0;
    float bgBright = 0.03 + u_bassEnergy * 0.02;
    vec3 bgColor = hsv2rgb(vec3(bgHue, 0.3, bgBright));

    // Render based on system (using step functions, no int)
    vec3 color;
    float isQuantum = step(u_system, 0.5);
    float isFaceted = step(0.5, u_system) * step(u_system, 1.5);
    float isHolo = step(1.5, u_system);

    color = renderQuantum(uv, d, p) * isQuantum;
    color += renderFaceted(uv, d, p) * isFaceted;
    color += renderHolographic(uv, d, p) * isHolo;

    // Combine with background
    color = max(color, bgColor);

    // Vignette
    color *= 1.0 - length(uv) * 0.4;

    // Clamp and premultiply alpha (Flutter requirement)
    color = clamp(color, 0.0, 1.0);
    fragColor = vec4(color, 1.0);
}
