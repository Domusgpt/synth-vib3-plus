#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

// Uniforms
uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;
uniform float u_geometry;
uniform float u_gridDensity;
uniform float u_morphFactor;
uniform float u_chaos;
uniform float u_speed;
uniform float u_hue;
uniform float u_intensity;
uniform float u_saturation;
uniform float u_rot4dXW;
uniform float u_rot4dYW;
uniform float u_rot4dZW;
uniform float u_mouseIntensity;
uniform float u_clickIntensity;
uniform float u_layerSeparation;

out vec4 fragColor;

// 4D rotation matrices
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

// Geometry functions
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

// Layer colors - holographic rainbow spectrum
vec3 getHolographicColor(int layer, float t, float hueBase) {
    float hue = hueBase / 360.0 + float(layer) * 0.12 + t * 0.1;

    // HSL to RGB
    vec3 color = vec3(
        sin(hue * 6.28318 + 0.0) * 0.5 + 0.5,
        sin(hue * 6.28318 + 2.0943) * 0.5 + 0.5,
        sin(hue * 6.28318 + 4.1887) * 0.5 + 0.5
    );

    // Add layer-specific tint
    if (layer == 0) color *= vec3(0.5, 0.3, 1.0);      // Purple background
    else if (layer == 1) color *= vec3(0.3, 1.0, 0.5); // Green shadow
    else if (layer == 2) color *= vec3(1.0, 0.5, 0.3); // Orange content
    else if (layer == 3) color *= vec3(0.3, 1.0, 1.0); // Cyan highlight
    else color *= vec3(1.0, 0.3, 1.0);                 // Magenta accent

    return color;
}

// Render single layer
vec4 renderLayer(vec2 uv, int layer, float timeSpeed) {
    // Layer-specific depth offset for parallax
    float layerDepth = float(layer) * u_layerSeparation * 0.1;
    float layerSpeed = 1.0 + float(layer - 2) * 0.15; // Vary speed per layer

    vec4 pos = vec4(uv * 3.0, sin(timeSpeed * 3.0) + layerDepth, cos(timeSpeed * 2.0) + layerDepth);
    pos.xy += (u_mouse - 0.5) * u_mouseIntensity * 2.0;

    // Per-layer rotation with offset
    float rotOffset = layerDepth * 0.5;
    pos = rotateXW(u_rot4dXW * layerSpeed + rotOffset) * pos;
    pos = rotateYW(u_rot4dYW * layerSpeed + rotOffset) * pos;
    pos = rotateZW(u_rot4dZW * layerSpeed + rotOffset) * pos;

    int geomType = int(u_geometry);
    float value = geometryFunction(pos, geomType);

    float noise = sin(pos.x * 7.0) * cos(pos.y * 11.0) * sin(pos.z * 13.0);
    value += noise * u_chaos;

    float intensity = 1.0 - clamp(abs(value), 0.0, 1.0);
    intensity += u_clickIntensity * 0.2;

    // Layer alpha weights
    float alphas[5] = float[5](0.3, 0.4, 1.0, 0.7, 0.25);
    float layerAlpha = alphas[layer];

    vec3 color = getHolographicColor(layer, timeSpeed + value, u_hue);
    color *= intensity * u_intensity;

    // Add holographic shimmer per layer
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

        // Additive blending for holographic effect
        result.rgb += layer.rgb * layer.a;
        result.a = max(result.a, layer.a);
    }

    // Clamp and apply final intensity
    result.rgb = clamp(result.rgb, 0.0, 1.0);

    // Add overall holographic iridescence
    float iridescence = sin(uv.x * 50.0 + uv.y * 30.0 + timeSpeed * 10.0) * 0.05;
    result.rgb += vec3(iridescence, iridescence * 0.8, iridescence * 1.2);

    fragColor = result;
}
