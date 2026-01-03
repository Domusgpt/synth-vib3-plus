/*
 * VIB3+ Core Fragment Shader - Flutter Native
 *
 * LATTICE-BASED rendering matching VIB3-CORE WebGL.
 * Full-screen tiled patterns with domain repetition.
 * 3 visual systems: Quantum, Faceted, Holographic
 * 24 geometries (8 base x 3 cores) with full 6D rotation
 *
 * FLUTTER GLSL COMPLIANCE:
 * - Uses FlutterFragCoord() not gl_FragCoord
 * - No int types - uses float + step()
 * - Handles GLES y-axis inversion
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
// 4D ROTATION MATRICES
// ============================================================

mat4 rotateXY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat4(c, -s, 0.0, 0.0, s, c, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0);
}

mat4 rotateXZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat4(c, 0.0, s, 0.0, 0.0, 1.0, 0.0, 0.0, -s, 0.0, c, 0.0, 0.0, 0.0, 0.0, 1.0);
}

mat4 rotateYZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat4(1.0, 0.0, 0.0, 0.0, 0.0, c, -s, 0.0, 0.0, s, c, 0.0, 0.0, 0.0, 0.0, 1.0);
}

mat4 rotateXW(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat4(c, 0.0, 0.0, -s, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, s, 0.0, 0.0, c);
}

mat4 rotateYW(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat4(1.0, 0.0, 0.0, 0.0, 0.0, c, 0.0, -s, 0.0, 0.0, 1.0, 0.0, 0.0, s, 0.0, c);
}

mat4 rotateZW(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat4(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, c, -s, 0.0, 0.0, s, c);
}

vec3 project4Dto3D(vec4 p) {
    float w = 2.5 / (2.5 + p.w);
    return vec3(p.x * w, p.y * w, p.z * w);
}

// ============================================================
// POLYTOPE CORE WARP FUNCTIONS (for geometries 8-23)
// ============================================================

vec3 warpHypersphereCore(vec3 p, float geometryIndex) {
    float radius = length(p);
    float morphBlend = clamp(u_morphFactor * 0.6, 0.0, 2.0);
    float w = sin(radius * (1.3 + geometryIndex * 0.12) + u_time * 0.0008);
    w *= (0.4 + morphBlend * 0.45);

    vec4 p4d = vec4(p * (1.0 + morphBlend * 0.2), w);
    p4d = rotateXY(u_rotXY) * p4d;
    p4d = rotateXZ(u_rotXZ) * p4d;
    p4d = rotateYZ(u_rotYZ) * p4d;
    p4d = rotateXW(u_rotXW) * p4d;
    p4d = rotateYW(u_rotYW) * p4d;
    p4d = rotateZW(u_rotZW) * p4d;

    vec3 projected = project4Dto3D(p4d);
    return mix(p, projected, clamp(0.45 + morphBlend * 0.35, 0.0, 1.0));
}

vec3 warpHypertetraCore(vec3 p, float geometryIndex) {
    vec3 c1 = normalize(vec3(1.0, 1.0, 1.0));
    vec3 c2 = normalize(vec3(-1.0, -1.0, 1.0));
    vec3 c3 = normalize(vec3(-1.0, 1.0, -1.0));
    vec3 c4 = normalize(vec3(1.0, -1.0, -1.0));

    float morphBlend = clamp(u_morphFactor * 0.8, 0.0, 2.0);
    float basisMix = dot(p, c1) * 0.14 + dot(p, c2) * 0.1 + dot(p, c3) * 0.08;
    float w = sin(basisMix * 5.5 + u_time * 0.0009);
    w *= cos(dot(p, c4) * 4.2 - u_time * 0.0007);
    w *= (0.5 + morphBlend * 0.4);

    vec3 offset = vec3(dot(p, c1), dot(p, c2), dot(p, c3)) * 0.1 * morphBlend;
    vec4 p4d = vec4(p + offset, w);
    p4d = rotateXY(u_rotXY) * p4d;
    p4d = rotateXZ(u_rotXZ) * p4d;
    p4d = rotateYZ(u_rotYZ) * p4d;
    p4d = rotateXW(u_rotXW) * p4d;
    p4d = rotateYW(u_rotYW) * p4d;
    p4d = rotateZW(u_rotZW) * p4d;

    vec3 projected = project4Dto3D(p4d);
    return mix(p, projected, clamp(0.45 + morphBlend * 0.35, 0.0, 1.0));
}

vec3 applyCoreWarp(vec3 p, float geometryType) {
    float coreIndex = floor(geometryType / 8.0);
    float baseGeom = mod(geometryType, 8.0);

    // Core 1: Hypersphere (geometries 8-15)
    float isHypersphere = step(0.5, coreIndex) * step(coreIndex, 1.5);
    vec3 hypersphereP = warpHypersphereCore(p, baseGeom);

    // Core 2: Hypertetra (geometries 16-23)
    float isHypertetra = step(1.5, coreIndex);
    vec3 hypertetraP = warpHypertetraCore(p, baseGeom);

    return p * (1.0 - isHypersphere - isHypertetra) +
           hypersphereP * isHypersphere +
           hypertetraP * isHypertetra;
}

// ============================================================
// LATTICE FUNCTIONS - Full screen tiled patterns
// ============================================================

float tetrahedronLattice(vec3 p, float gridSize) {
    vec3 q = fract(p * gridSize) - 0.5;
    float d1 = length(q);
    float d2 = length(q - vec3(0.4, 0.0, 0.0));
    float d3 = length(q - vec3(0.0, 0.4, 0.0));
    float d4 = length(q - vec3(0.0, 0.0, 0.4));
    float vertices = 1.0 - smoothstep(0.0, 0.04, min(min(d1, d2), min(d3, d4)));
    float edges = 0.0;
    edges = max(edges, 1.0 - smoothstep(0.0, 0.02, abs(length(q.xy) - 0.2)));
    edges = max(edges, 1.0 - smoothstep(0.0, 0.02, abs(length(q.yz) - 0.2)));
    edges = max(edges, 1.0 - smoothstep(0.0, 0.02, abs(length(q.xz) - 0.2)));
    return max(vertices, edges * 0.5);
}

float hypercubeLattice(vec3 p, float gridSize) {
    vec3 grid = fract(p * gridSize);
    vec3 edges = min(grid, 1.0 - grid);
    float minEdge = min(min(edges.x, edges.y), edges.z);
    float lattice = 1.0 - smoothstep(0.0, 0.03, minEdge);

    vec3 centers = abs(grid - 0.5);
    float maxCenter = max(max(centers.x, centers.y), centers.z);
    float vertices = 1.0 - smoothstep(0.45, 0.5, maxCenter);

    return max(lattice * 0.7, vertices);
}

float sphereLattice(vec3 p, float gridSize) {
    vec3 cell = fract(p * gridSize) - 0.5;
    float sphere = 1.0 - smoothstep(0.15, 0.25, length(cell));

    float rings = 0.0;
    float ringRadius = length(cell.xy);
    rings = max(rings, 1.0 - smoothstep(0.0, 0.02, abs(ringRadius - 0.3)));
    rings = max(rings, 1.0 - smoothstep(0.0, 0.02, abs(ringRadius - 0.2)));

    return max(sphere, rings * 0.6);
}

float torusLattice(vec3 p, float gridSize) {
    vec3 cell = fract(p * gridSize) - 0.5;
    float majorRadius = 0.3;
    float minorRadius = 0.1;

    float toroidalDist = length(vec2(length(cell.xy) - majorRadius, cell.z));
    float torus = 1.0 - smoothstep(minorRadius - 0.02, minorRadius + 0.02, toroidalDist);

    float angle = atan(cell.y, cell.x);
    float rings = sin(angle * 8.0) * 0.02;

    return max(torus, 0.0) + rings;
}

float kleinLattice(vec3 p, float gridSize) {
    vec3 cell = fract(p * gridSize) - 0.5;
    float u = atan(cell.y, cell.x) / PI + 1.0;
    float v = cell.z + 0.5;

    float x = (2.0 + cos(u * 0.5)) * cos(u);
    float y = (2.0 + cos(u * 0.5)) * sin(u);
    float z = sin(u * 0.5) + v;

    vec3 kleinPoint = vec3(x, y, z) * 0.1;
    float dist = length(cell - kleinPoint);

    return 1.0 - smoothstep(0.1, 0.15, dist);
}

float fractalLattice(vec3 p, float gridSize) {
    vec3 cell = fract(p * gridSize);
    cell = abs(cell * 2.0 - 1.0);

    float dist = length(max(abs(cell) - 0.3, 0.0));

    // Recursive subdivision (unrolled for Flutter GLSL)
    cell = abs(cell * 2.0 - 1.0);
    float subdist1 = length(max(abs(cell) - 0.3, 0.0)) / 2.0;
    dist = min(dist, subdist1);

    cell = abs(cell * 2.0 - 1.0);
    float subdist2 = length(max(abs(cell) - 0.3, 0.0)) / 4.0;
    dist = min(dist, subdist2);

    cell = abs(cell * 2.0 - 1.0);
    float subdist3 = length(max(abs(cell) - 0.3, 0.0)) / 8.0;
    dist = min(dist, subdist3);

    return 1.0 - smoothstep(0.0, 0.05, dist);
}

float waveLattice(vec3 p, float gridSize) {
    float time = u_time * 0.001;
    vec3 cell = fract(p * gridSize) - 0.5;

    float wave1 = sin(p.x * gridSize * 2.0 + time * 2.0);
    float wave2 = sin(p.y * gridSize * 1.8 + time * 1.5);
    float wave3 = sin(p.z * gridSize * 2.2 + time * 1.8);

    float interference = (wave1 + wave2 + wave3) / 3.0;
    float amplitude = 1.0 - length(cell) * 2.0;

    return max(0.0, interference * amplitude);
}

float crystalLattice(vec3 p, float gridSize) {
    vec3 cell = fract(p * gridSize) - 0.5;

    // Octahedral crystal structure
    float crystal = max(max(abs(cell.x) + abs(cell.y), abs(cell.y) + abs(cell.z)), abs(cell.x) + abs(cell.z));
    crystal = 1.0 - smoothstep(0.3, 0.4, crystal);

    // Crystalline faces
    float faces = 0.0;
    faces = max(faces, 1.0 - smoothstep(0.0, 0.02, abs(abs(cell.x) - 0.35)));
    faces = max(faces, 1.0 - smoothstep(0.0, 0.02, abs(abs(cell.y) - 0.35)));
    faces = max(faces, 1.0 - smoothstep(0.0, 0.02, abs(abs(cell.z) - 0.35)));

    return max(crystal, faces * 0.5);
}

// Geometry function with lattice selection (using step functions for Flutter)
float geometryFunction(vec4 p) {
    float baseGeom = mod(u_geometry, 8.0);

    vec3 p3d = project4Dto3D(p);
    vec3 warped = applyCoreWarp(p3d, u_geometry);
    float gridSize = u_gridDensity * 0.08 + 1.0;

    // Audio-reactive grid modulation
    gridSize *= 1.0 + u_bassEnergy * 0.3;

    // Select lattice function using step (Flutter GLSL compatible)
    float value = tetrahedronLattice(warped, gridSize);

    value = mix(value, hypercubeLattice(warped, gridSize),
                step(0.5, baseGeom) * step(baseGeom, 1.5));
    value = mix(value, sphereLattice(warped, gridSize),
                step(1.5, baseGeom) * step(baseGeom, 2.5));
    value = mix(value, torusLattice(warped, gridSize),
                step(2.5, baseGeom) * step(baseGeom, 3.5));
    value = mix(value, kleinLattice(warped, gridSize),
                step(3.5, baseGeom) * step(baseGeom, 4.5));
    value = mix(value, fractalLattice(warped, gridSize),
                step(4.5, baseGeom) * step(baseGeom, 5.5));
    value = mix(value, waveLattice(warped, gridSize),
                step(5.5, baseGeom) * step(baseGeom, 6.5));
    value = mix(value, crystalLattice(warped, gridSize),
                step(6.5, baseGeom));

    // morphFactor 0-1 scales intensity, but always show something
    return value * (0.5 + u_morphFactor * 0.5);
}

// ============================================================
// COLOR SYSTEMS - Quantum, Faceted, Holographic
// ============================================================

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// QUANTUM: Multi-layer with extreme RGB separation
vec3 renderQuantum(vec2 uv, float geometryValue, vec4 pos) {
    float time = u_time * 0.001;

    // 5-layer color system
    vec3 bgColor = vec3(0.05, 0.0, 0.15);  // Deep purple
    vec3 shadowColor = vec3(0.0, 0.8, 0.3);  // Toxic green
    vec3 contentColor = vec3(1.0, 0.3, 0.5);  // Hot pink/red
    vec3 highlightColor = vec3(0.0, 1.0, 1.0);  // Electric cyan
    vec3 accentColor = vec3(1.0, 0.0, 1.0);  // Magenta

    // Hue shift from parameter
    float hueShift = u_hue / 360.0;
    bgColor = hsv2rgb(vec3(hueShift + 0.75, 0.8, 0.15));
    contentColor = hsv2rgb(vec3(hueShift, 0.9, 0.9));
    highlightColor = hsv2rgb(vec3(hueShift + 0.5, 0.8, 1.0));

    // Geometry intensity with dramatic falloff
    float intensity = pow(geometryValue, 1.5);
    intensity += u_rmsAmplitude * 0.3;

    // Layer blending
    vec3 color = bgColor * (0.3 + intensity * 0.2);
    color += contentColor * intensity * 0.8;
    color += highlightColor * pow(intensity, 3.0) * 0.5;

    // Extreme RGB separation
    float sepIntensity = u_rgbSplit * 0.01 + u_highEnergy * 0.02;
    color.r += sin(uv.y * 50.0 + time * 3.0) * sepIntensity;
    color.g += sin((uv.y + 0.1) * 45.0 + time * 2.5) * sepIntensity * 0.8;
    color.b += sin((uv.y - 0.1) * 55.0 + time * 3.5) * sepIntensity * 1.2;

    // Particles on high intensity areas
    vec2 particleUV = uv * 15.0;
    vec2 particleID = floor(particleUV);
    vec2 particlePos = fract(particleUV) - 0.5;
    float particleDist = length(particlePos);
    float particleTime = time * 3.0 + dot(particleID, vec2(127.1, 311.7));
    float particleAlpha = sin(particleTime) * 0.5 + 0.5;
    float particles = (1.0 - smoothstep(0.05, 0.15, particleDist)) * particleAlpha * intensity;
    color += vec3(1.0) * particles * 0.3;

    return color * u_brightness;
}

// FACETED: Clean geometric with sharp edges
vec3 renderFaceted(vec2 uv, float geometryValue, vec4 pos) {
    float time = u_time * 0.001;

    // Cooler color palette for faceted
    float hueShift = u_hue / 360.0;
    vec3 edgeColor = hsv2rgb(vec3(hueShift + 0.6, 0.7, 0.8));  // Blue-ish
    vec3 fillColor = hsv2rgb(vec3(hueShift + 0.55, 0.4, 0.2));  // Darker
    vec3 glowColor = hsv2rgb(vec3(hueShift + 0.65, 0.9, 1.0));  // Bright

    // Sharp edge detection
    float edge = smoothstep(0.3, 0.5, geometryValue) - smoothstep(0.5, 0.7, geometryValue);
    float fill = smoothstep(0.0, 0.3, geometryValue) * 0.3;

    vec3 color = fillColor * fill;
    color += edgeColor * edge * (0.8 + u_midEnergy * 0.4);
    color += glowColor * pow(geometryValue, 4.0) * u_glowIntensity * 0.5;

    // Subtle vertex highlights
    float vertGlow = pow(geometryValue, 6.0) * u_highEnergy;
    color += vec3(1.0) * vertGlow * 0.3;

    return color * u_brightness;
}

// HOLOGRAPHIC: Multi-depth with chromatic aberration and moire
vec3 renderHolographic(vec2 uv, float geometryValue, vec4 pos) {
    float time = u_time * 0.001;
    vec3 color = vec3(0.0);

    // Multi-layer depth effect
    for (float layer = 0.0; layer < 5.0; layer += 1.0) {
        float depth = layer / 4.0;
        float layerOffset = (layer - 2.0) * 0.08;
        float layerValue = geometryValue + layerOffset + pos.w * 0.1 * depth;

        float layerHue = (u_hue + layer * 25.0) / 360.0;
        float layerAlpha = 0.15 + depth * 0.25 + u_rmsAmplitude * 0.15;
        vec3 layerCol = hsv2rgb(vec3(layerHue, 0.7 + u_saturation * 0.2, 0.5 + depth * 0.2));

        float edge = 1.0 - smoothstep(0.0, 0.06 + u_glowIntensity * 0.02, abs(layerValue - 0.5));
        color += layerCol * edge * layerAlpha;
    }

    // Chromatic aberration
    float dist = length(uv);
    float aberr = u_rgbSplit * 0.01;
    color.r *= 1.0 + sin(dist * 10.0 + time) * aberr;
    color.g *= 1.0 + sin(dist * 10.0 + time + 2.09) * aberr;
    color.b *= 1.0 + sin(dist * 10.0 + time + 4.18) * aberr;

    // Holographic shimmer
    float shimmer = sin(uv.x * 50.0 + time * 2.0) * sin(uv.y * 50.0 + time * 1.5);
    color += vec3(shimmer * 0.05 * u_glowIntensity);

    // Moire interference pattern
    float moire = sin(dist * u_gridDensity * 5.0 + time) * 0.5 + 0.5;
    moire *= sin(dist * u_gridDensity * 5.5 - time * 0.5) * 0.5 + 0.5;
    color *= 0.9 + moire * 0.2;

    return color * u_brightness;
}

// ============================================================
// MAIN
// ============================================================

void main() {
    vec2 fragCoord = FlutterFragCoord();

    #ifdef IMPELLER_TARGET_OPENGLES
    fragCoord.y = u_resolution.y - fragCoord.y;
    #endif

    vec2 uv = (fragCoord - u_resolution * 0.5) / min(u_resolution.x, u_resolution.y);

    // Create 4D position with time-based depth
    float timeSpeed = u_time * 0.0001;
    vec4 pos = vec4(uv * 3.0, sin(timeSpeed * 3.0), cos(timeSpeed * 2.0));

    // Apply 6D rotations
    pos = rotateXY(u_rotXY + timeSpeed * 0.5) * pos;
    pos = rotateXZ(u_rotXZ + timeSpeed * 0.4) * pos;
    pos = rotateYZ(u_rotYZ + timeSpeed * 0.3) * pos;
    pos = rotateXW(u_rotXW + timeSpeed * 0.6) * pos;
    pos = rotateYW(u_rotYW + timeSpeed * 0.5) * pos;
    pos = rotateZW(u_rotZW + timeSpeed * 0.7) * pos;

    // Audio modulation of rotation
    pos = rotateXY(u_bassEnergy * 0.2) * pos;
    pos = rotateYZ(u_midEnergy * 0.15) * pos;

    // Calculate geometry value
    float value = geometryFunction(pos);

    // Add chaos noise
    float noise = sin(pos.x * 7.0) * cos(pos.y * 11.0) * sin(pos.z * 13.0);
    value += noise * u_chaos * 0.3;

    // Render based on visual system
    vec3 color;
    float isQuantum = step(u_system, 0.5);
    float isFaceted = step(0.5, u_system) * step(u_system, 1.5);
    float isHolo = step(1.5, u_system);

    color = renderQuantum(uv, value, pos) * isQuantum;
    color += renderFaceted(uv, value, pos) * isFaceted;
    color += renderHolographic(uv, value, pos) * isHolo;

    // Vignette
    float vignette = 1.0 - length(uv) * 0.3;
    color *= vignette;

    // Final output with premultiplied alpha
    color = clamp(color, 0.0, 1.0);
    fragColor = vec4(color, 1.0);
}
