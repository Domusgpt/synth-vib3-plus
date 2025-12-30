#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

// Uniforms - passed from Dart
uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_geometry;      // 0-23: includes core selection
uniform float u_gridDensity;
uniform float u_morphFactor;
uniform float u_chaos;
uniform float u_speed;
uniform float u_hue;
uniform float u_intensity;
uniform float u_saturation;
uniform float u_dimension;

// VIB3+ COMPLETE 6D ROTATION SYSTEM
uniform float u_rot4dXY;       // 3D space rotation (roll)
uniform float u_rot4dXZ;       // 3D space rotation (pitch)
uniform float u_rot4dYZ;       // 3D space rotation (yaw)
uniform float u_rot4dXW;       // 4D hyperspace rotation
uniform float u_rot4dYW;       // 4D hyperspace rotation
uniform float u_rot4dZW;       // 4D hyperspace rotation

uniform float u_mouseIntensity;
uniform float u_clickIntensity;

// Output
out vec4 fragColor;

// ============================================
// VIB3+ COMPLETE 6D ROTATION MATRICES
// ============================================

// 3D Space Rotations
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

// 4D Hyperspace Rotations
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

// 4D to 3D projection
vec3 project4Dto3D(vec4 p) {
    float w = 2.5 / (2.5 + p.w);
    return vec3(p.x * w, p.y * w, p.z * w);
}

// ============================================
// VIB3+ 24-GEOMETRY POLYTOPE CORE WARPING
// ============================================

// Hypersphere Core Warp (geometries 8-15)
// Wraps geometry through 4D hypersphere - creates FM synthesis-like visual modulation
vec3 warpHypersphereCore(vec3 p, int geometryIndex) {
    float radius = length(p);
    float morphBlend = clamp(u_morphFactor * 0.6 + (u_dimension - 3.0) * 0.25, 0.0, 2.0);
    float timeSpeed = u_time * 0.0001 * u_speed;
    float w = sin(radius * (1.3 + float(geometryIndex) * 0.12) + timeSpeed * 8.0);
    w *= (0.4 + morphBlend * 0.45);

    vec4 p4d = vec4(p * (1.0 + morphBlend * 0.2), w);

    // Apply full 6D rotation in 4D space
    p4d = rotateXY(u_rot4dXY) * p4d;
    p4d = rotateXZ(u_rot4dXZ) * p4d;
    p4d = rotateYZ(u_rot4dYZ) * p4d;
    p4d = rotateXW(u_rot4dXW) * p4d;
    p4d = rotateYW(u_rot4dYW) * p4d;
    p4d = rotateZW(u_rot4dZW) * p4d;

    vec3 projected = project4Dto3D(p4d);
    return mix(p, projected, clamp(0.45 + morphBlend * 0.35, 0.0, 1.0));
}

// Hypertetrahedron Core Warp (geometries 16-23)
// Wraps geometry through 4D hypertetrahedron - creates ring modulation-like visual modulation
vec3 warpHypertetraCore(vec3 p, int geometryIndex) {
    vec3 c1 = normalize(vec3(1.0, 1.0, 1.0));
    vec3 c2 = normalize(vec3(-1.0, -1.0, 1.0));
    vec3 c3 = normalize(vec3(-1.0, 1.0, -1.0));
    vec3 c4 = normalize(vec3(1.0, -1.0, -1.0));

    float morphBlend = clamp(u_morphFactor * 0.8 + (u_dimension - 3.0) * 0.2, 0.0, 2.0);
    float timeSpeed = u_time * 0.0001 * u_speed;
    float basisMix = dot(p, c1) * 0.14 + dot(p, c2) * 0.1 + dot(p, c3) * 0.08;
    float w = sin(basisMix * 5.5 + timeSpeed * 9.0);
    w *= cos(dot(p, c4) * 4.2 - timeSpeed * 7.0);
    w *= (0.5 + morphBlend * 0.4);

    vec3 offset = vec3(dot(p, c1), dot(p, c2), dot(p, c3)) * 0.1 * morphBlend;
    vec4 p4d = vec4(p + offset, w);

    // Apply full 6D rotation in 4D space
    p4d = rotateXY(u_rot4dXY) * p4d;
    p4d = rotateXZ(u_rot4dXZ) * p4d;
    p4d = rotateYZ(u_rot4dYZ) * p4d;
    p4d = rotateXW(u_rot4dXW) * p4d;
    p4d = rotateYW(u_rot4dYW) * p4d;
    p4d = rotateZW(u_rot4dZW) * p4d;

    vec3 projected = project4Dto3D(p4d);

    float planeInfluence = min(min(abs(dot(p, c1)), abs(dot(p, c2))), min(abs(dot(p, c3)), abs(dot(p, c4))));
    vec3 blended = mix(p, projected, clamp(0.45 + morphBlend * 0.35, 0.0, 1.0));
    return mix(blended, blended * (1.0 - planeInfluence * 0.55), 0.2 + morphBlend * 0.2);
}

// Apply polytope core warp based on geometry index (0-23)
// 0-7: Base (no warp), 8-15: Hypersphere, 16-23: Hypertetrahedron
vec3 applyCoreWarp(vec3 p, float geometryType) {
    float totalBase = 8.0;
    float coreFloat = floor(geometryType / totalBase);
    int coreIndex = int(clamp(coreFloat, 0.0, 2.0));
    float baseGeomFloat = mod(geometryType, totalBase);
    int geometryIndex = int(clamp(floor(baseGeomFloat + 0.5), 0.0, totalBase - 1.0));

    if (coreIndex == 1) {
        return warpHypersphereCore(p, geometryIndex);
    }
    if (coreIndex == 2) {
        return warpHypertetraCore(p, geometryIndex);
    }
    return p;
}

// ============================================
// 8 BASE GEOMETRY FUNCTIONS
// ============================================

float geometryFunction(vec4 p, int geomType) {
    float density = u_gridDensity * 0.08;

    if (geomType == 0) {
        // Tetrahedron lattice
        vec4 pos = fract(p * density);
        vec4 dist = min(pos, 1.0 - pos);
        return min(min(dist.x, dist.y), min(dist.z, dist.w)) * u_morphFactor;
    }
    else if (geomType == 1) {
        // Hypercube lattice
        vec4 pos = fract(p * density);
        vec4 dist = min(pos, 1.0 - pos);
        float minDist = min(min(dist.x, dist.y), min(dist.z, dist.w));
        return minDist * u_morphFactor;
    }
    else if (geomType == 2) {
        // Sphere lattice
        float r = length(p);
        float spheres = abs(fract(r * density) - 0.5) * 2.0;
        float theta = atan(p.y, p.x);
        float harmonics = sin(theta * 3.0) * 0.2;
        return (spheres + harmonics) * u_morphFactor;
    }
    else if (geomType == 3) {
        // Torus lattice
        float r1 = length(p.xy) - 2.0;
        float torus = length(vec2(r1, p.z)) - 0.8;
        float lattice = sin(p.x * density) * sin(p.y * density);
        return (torus + lattice * 0.3) * u_morphFactor;
    }
    else if (geomType == 4) {
        // Klein bottle lattice
        float u = atan(p.y, p.x);
        float v = atan(p.w, p.z);
        float dist = length(p) - 2.0;
        float lattice = sin(u * density) * sin(v * density);
        return (dist + lattice * 0.4) * u_morphFactor;
    }
    else if (geomType == 5) {
        // Fractal lattice
        vec4 pos = fract(p * density);
        pos = abs(pos * 2.0 - 1.0);
        float dist = length(max(abs(pos) - 1.0, 0.0));
        return dist * u_morphFactor;
    }
    else if (geomType == 6) {
        // Wave lattice
        float freq = density;
        float time = u_time * 0.001 * u_speed;
        float wave1 = sin(p.x * freq + time);
        float wave2 = sin(p.y * freq + time * 1.3);
        float wave3 = sin(p.z * freq * 0.8 + time * 0.7);
        float interference = wave1 * wave2 * wave3;
        return interference * u_morphFactor;
    }
    else if (geomType == 7) {
        // Crystal lattice
        vec4 pos = fract(p * density) - 0.5;
        float cube = max(max(abs(pos.x), abs(pos.y)), max(abs(pos.z), abs(pos.w)));
        return cube * u_morphFactor;
    }

    // Default hypercube
    vec4 pos = fract(p * density);
    vec4 dist = min(pos, 1.0 - pos);
    return min(min(dist.x, dist.y), min(dist.z, dist.w)) * u_morphFactor;
}

void main() {
    vec2 uv = (FlutterFragCoord().xy - u_resolution.xy * 0.5) / min(u_resolution.x, u_resolution.y);

    // 4D position with mouse interaction
    float timeSpeed = u_time * 0.0001 * u_speed;
    vec4 pos = vec4(uv * 3.0, sin(timeSpeed * 3.0), cos(timeSpeed * 2.0));
    pos.xy += (u_mouse - 0.5) * u_mouseIntensity * 2.0;

    // Apply full 6D rotations - 3D space first, then 4D hyperspace
    pos = rotateXY(u_rot4dXY) * pos;
    pos = rotateXZ(u_rot4dXZ) * pos;
    pos = rotateYZ(u_rot4dYZ) * pos;
    pos = rotateXW(u_rot4dXW) * pos;
    pos = rotateYW(u_rot4dYW) * pos;
    pos = rotateZW(u_rot4dZW) * pos;

    // VIB3+ POLYTOPE WARP: Apply 4D polytope core transformation (24-geometry system)
    // Decode geometry: 0-7 Base, 8-15 Hypersphere, 16-23 Hypertetrahedron
    vec3 basePoint = project4Dto3D(pos);
    vec3 warpedPoint = applyCoreWarp(basePoint, u_geometry);

    // Convert warped 3D back to 4D for geometry evaluation
    vec4 warpedPos = vec4(warpedPoint, pos.w);

    // Decode base geometry type (0-7) from full geometry index (0-23)
    int geomType = int(mod(u_geometry, 8.0));
    float value = geometryFunction(warpedPos, geomType);

    // Apply chaos
    float noise = sin(pos.x * 7.0) * cos(pos.y * 11.0) * sin(pos.z * 13.0);
    value += noise * u_chaos;

    // Color based on geometry value and hue
    float geometryIntensity = 1.0 - clamp(abs(value), 0.0, 1.0);
    geometryIntensity += u_clickIntensity * 0.3;

    // Apply user intensity control
    float finalIntensity = geometryIntensity * u_intensity;

    float hue = u_hue / 360.0 + value * 0.1;

    // Create color with saturation control
    vec3 baseColor = vec3(
        sin(hue * 6.28318 + 0.0) * 0.5 + 0.5,
        sin(hue * 6.28318 + 2.0943) * 0.5 + 0.5,
        sin(hue * 6.28318 + 4.1887) * 0.5 + 0.5
    );

    // Apply saturation (mix with grayscale)
    float gray = (baseColor.r + baseColor.g + baseColor.b) / 3.0;
    vec3 color = mix(vec3(gray), baseColor, u_saturation) * finalIntensity;

    fragColor = vec4(color, finalIntensity);
}
