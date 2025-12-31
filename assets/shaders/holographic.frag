#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

// Uniforms
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
uniform float u_layerSeparation;

out vec4 fragColor;

// ============================================
// VIB3+ COMPLETE 6D ROTATION MATRICES
// ============================================

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

// ============================================
// VIB3+ 24-GEOMETRY POLYTOPE CORE WARPING
// ============================================

vec3 warpHypersphereCore(vec3 p, int geometryIndex) {
    float radius = length(p);
    float morphBlend = clamp(u_morphFactor * 0.6 + (u_dimension - 3.0) * 0.25, 0.0, 2.0);
    float timeSpeed = u_time * 0.0001 * u_speed;
    float w = sin(radius * (1.3 + float(geometryIndex) * 0.12) + timeSpeed * 8.0);
    w *= (0.4 + morphBlend * 0.45);

    vec4 p4d = vec4(p * (1.0 + morphBlend * 0.2), w);
    p4d = rotateXY(u_rot4dXY) * p4d;
    p4d = rotateXZ(u_rot4dXZ) * p4d;
    p4d = rotateYZ(u_rot4dYZ) * p4d;
    p4d = rotateXW(u_rot4dXW) * p4d;
    p4d = rotateYW(u_rot4dYW) * p4d;
    p4d = rotateZW(u_rot4dZW) * p4d;

    vec3 projected = project4Dto3D(p4d);
    return mix(p, projected, clamp(0.45 + morphBlend * 0.35, 0.0, 1.0));
}

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

vec3 applyCoreWarp(vec3 p, float geometryType) {
    float totalBase = 8.0;
    int coreIndex = int(clamp(floor(geometryType / totalBase), 0.0, 2.0));
    int geometryIndex = int(clamp(mod(geometryType, totalBase), 0.0, 7.0));

    if (coreIndex == 1) return warpHypersphereCore(p, geometryIndex);
    if (coreIndex == 2) return warpHypertetraCore(p, geometryIndex);
    return p;
}

// ============================================
// 8 BASE GEOMETRY FUNCTIONS
// ============================================

float geometryFunction(vec4 p, int geomType) {
    float density = u_gridDensity * 0.08;

    if (geomType == 0) {
        vec4 pos = fract(p * density);
        vec4 dist = min(pos, 1.0 - pos);
        return min(min(dist.x, dist.y), min(dist.z, dist.w)) * u_morphFactor;
    }
    else if (geomType == 1) {
        vec4 pos = fract(p * density);
        vec4 dist = min(pos, 1.0 - pos);
        return min(min(dist.x, dist.y), min(dist.z, dist.w)) * u_morphFactor;
    }
    else if (geomType == 2) {
        float r = length(p);
        float spheres = abs(fract(r * density) - 0.5) * 2.0;
        float theta = atan(p.y, p.x);
        float harmonics = sin(theta * 3.0) * 0.2;
        return (spheres + harmonics) * u_morphFactor;
    }
    else if (geomType == 3) {
        float r1 = length(p.xy) - 2.0;
        float torus = length(vec2(r1, p.z)) - 0.8;
        float lattice = sin(p.x * density) * sin(p.y * density);
        return (torus + lattice * 0.3) * u_morphFactor;
    }
    else if (geomType == 4) {
        float u = atan(p.y, p.x);
        float v = atan(p.w, p.z);
        float dist = length(p) - 2.0;
        float lattice = sin(u * density) * sin(v * density);
        return (dist + lattice * 0.4) * u_morphFactor;
    }
    else if (geomType == 5) {
        vec4 pos = fract(p * density);
        pos = abs(pos * 2.0 - 1.0);
        float dist = length(max(abs(pos) - 1.0, 0.0));
        return dist * u_morphFactor;
    }
    else if (geomType == 6) {
        float freq = density;
        float time = u_time * 0.001 * u_speed;
        float wave1 = sin(p.x * freq + time);
        float wave2 = sin(p.y * freq + time * 1.3);
        float wave3 = sin(p.z * freq * 0.8 + time * 0.7);
        return wave1 * wave2 * wave3 * u_morphFactor;
    }
    else if (geomType == 7) {
        vec4 pos = fract(p * density) - 0.5;
        float cube = max(max(abs(pos.x), abs(pos.y)), max(abs(pos.z), abs(pos.w)));
        return cube * u_morphFactor;
    }

    vec4 pos = fract(p * density);
    vec4 dist = min(pos, 1.0 - pos);
    return min(min(dist.x, dist.y), min(dist.z, dist.w)) * u_morphFactor;
}

// ============================================
// HOLOGRAPHIC 5-LAYER COMPOSITING SYSTEM
// ============================================

vec3 getHolographicColor(int layer, float t, float hueBase) {
    float hue = hueBase / 360.0 + float(layer) * 0.12 + t * 0.1;

    vec3 color = vec3(
        sin(hue * 6.28318 + 0.0) * 0.5 + 0.5,
        sin(hue * 6.28318 + 2.0943) * 0.5 + 0.5,
        sin(hue * 6.28318 + 4.1887) * 0.5 + 0.5
    );

    if (layer == 0) color *= vec3(0.5, 0.3, 1.0);      // Purple background
    else if (layer == 1) color *= vec3(0.3, 1.0, 0.5); // Green shadow
    else if (layer == 2) color *= vec3(1.0, 0.5, 0.3); // Orange content
    else if (layer == 3) color *= vec3(0.3, 1.0, 1.0); // Cyan highlight
    else color *= vec3(1.0, 0.3, 1.0);                 // Magenta accent

    return color;
}

vec4 renderLayer(vec2 uv, int layer, float timeSpeed) {
    float layerDepth = float(layer) * u_layerSeparation * 0.1;
    float layerSpeed = 1.0 + float(layer - 2) * 0.15;

    vec4 pos = vec4(uv * 3.0, sin(timeSpeed * 3.0) + layerDepth, cos(timeSpeed * 2.0) + layerDepth);
    pos.xy += (u_mouse - 0.5) * u_mouseIntensity * 2.0;

    // Apply full 6D rotations with per-layer offset
    float rotOffset = layerDepth * 0.5;
    pos = rotateXY((u_rot4dXY + rotOffset) * layerSpeed) * pos;
    pos = rotateXZ((u_rot4dXZ + rotOffset) * layerSpeed) * pos;
    pos = rotateYZ((u_rot4dYZ + rotOffset) * layerSpeed) * pos;
    pos = rotateXW((u_rot4dXW + rotOffset) * layerSpeed) * pos;
    pos = rotateYW((u_rot4dYW + rotOffset) * layerSpeed) * pos;
    pos = rotateZW((u_rot4dZW + rotOffset) * layerSpeed) * pos;

    // VIB3+ POLYTOPE WARP
    vec3 basePoint = project4Dto3D(pos);
    vec3 warpedPoint = applyCoreWarp(basePoint, u_geometry);
    vec4 warpedPos = vec4(warpedPoint, pos.w);

    int geomType = int(mod(u_geometry, 8.0));
    float value = geometryFunction(warpedPos, geomType);

    float noise = sin(pos.x * 7.0) * cos(pos.y * 11.0) * sin(pos.z * 13.0);
    value += noise * u_chaos;

    float intensity = 1.0 - clamp(abs(value), 0.0, 1.0);
    intensity += u_clickIntensity * 0.2;

    // Layer alpha weights
    float layerAlpha;
    if (layer == 0) layerAlpha = 0.3;
    else if (layer == 1) layerAlpha = 0.4;
    else if (layer == 2) layerAlpha = 1.0;
    else if (layer == 3) layerAlpha = 0.7;
    else layerAlpha = 0.25;

    vec3 color = getHolographicColor(layer, timeSpeed + value, u_hue);
    color *= intensity * u_intensity;

    // Holographic shimmer per layer
    float shimmer = sin(uv.x * 30.0 + timeSpeed * 8.0 + float(layer) * 1.5) *
                    cos(uv.y * 25.0 + timeSpeed * 6.0 + float(layer) * 1.2) * 0.15;
    color += shimmer * color;

    return vec4(color, intensity * layerAlpha);
}

void main() {
    vec2 uv = (FlutterFragCoord().xy - u_resolution.xy * 0.5) / min(u_resolution.x, u_resolution.y);
    float timeSpeed = u_time * 0.0001 * u_speed;

    // Composite all 5 layers
    vec4 result = vec4(0.0);

    for (int i = 0; i < 5; i++) {
        vec4 layer = renderLayer(uv, i, timeSpeed);
        result.rgb += layer.rgb * layer.a;
        result.a = max(result.a, layer.a);
    }

    result.rgb = clamp(result.rgb, 0.0, 1.0);

    // Holographic iridescence
    float iridescence = sin(uv.x * 50.0 + uv.y * 30.0 + timeSpeed * 10.0) * 0.05;
    result.rgb += vec3(iridescence, iridescence * 0.8, iridescence * 1.2);

    // Apply saturation
    float gray = (result.r + result.g + result.b) / 3.0;
    result.rgb = mix(vec3(gray), result.rgb, u_saturation);

    fragColor = result;
}
