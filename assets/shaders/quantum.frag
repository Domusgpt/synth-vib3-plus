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
uniform float u_layerIndex;

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

vec3 project4Dto3D(vec4 p) {
    float w = 2.5 / (2.5 + p.w);
    return vec3(p.x * w, p.y * w, p.z * w);
}

// Complex 3D Lattice Functions
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
    float rings = 0.0;
    float angle = atan(cell.y, cell.x);
    rings = sin(angle * 8.0) * 0.02;
    return max(torus, 0.0) + rings;
}

float kleinLattice(vec3 p, float gridSize) {
    vec3 cell = fract(p * gridSize) - 0.5;
    float u = atan(cell.y, cell.x) / 3.14159 + 1.0;
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
    for(int i = 0; i < 3; i++) {
        cell = abs(cell * 2.0 - 1.0);
        float subdist = length(max(abs(cell) - 0.3, 0.0)) / pow(2.0, float(i + 1));
        dist = min(dist, subdist);
    }
    return 1.0 - smoothstep(0.0, 0.05, dist);
}

float waveLattice(vec3 p, float gridSize) {
    float time = u_time * 0.001 * u_speed;
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
    float crystal = max(max(abs(cell.x) + abs(cell.y), abs(cell.y) + abs(cell.z)), abs(cell.x) + abs(cell.z));
    crystal = 1.0 - smoothstep(0.3, 0.4, crystal);
    float faces = 0.0;
    faces = max(faces, 1.0 - smoothstep(0.0, 0.02, abs(abs(cell.x) - 0.35)));
    faces = max(faces, 1.0 - smoothstep(0.0, 0.02, abs(abs(cell.y) - 0.35)));
    faces = max(faces, 1.0 - smoothstep(0.0, 0.02, abs(abs(cell.z) - 0.35)));
    return max(crystal, faces * 0.5);
}

float geometryFunction(vec4 p, int geomType) {
    vec3 p3d = project4Dto3D(p);
    float gridSize = u_gridDensity * 0.08;

    if (geomType == 0) return tetrahedronLattice(p3d, gridSize) * u_morphFactor;
    else if (geomType == 1) return hypercubeLattice(p3d, gridSize) * u_morphFactor;
    else if (geomType == 2) return sphereLattice(p3d, gridSize) * u_morphFactor;
    else if (geomType == 3) return torusLattice(p3d, gridSize) * u_morphFactor;
    else if (geomType == 4) return kleinLattice(p3d, gridSize) * u_morphFactor;
    else if (geomType == 5) return fractalLattice(p3d, gridSize) * u_morphFactor;
    else if (geomType == 6) return waveLattice(p3d, gridSize) * u_morphFactor;
    else if (geomType == 7) return crystalLattice(p3d, gridSize) * u_morphFactor;
    return hypercubeLattice(p3d, gridSize) * u_morphFactor;
}

// Layer-specific color palettes
vec3 getLayerColorPalette(int layerIndex, float t) {
    if (layerIndex == 0) {
        // Background: Deep space colors
        vec3 color1 = vec3(0.05, 0.0, 0.2);
        vec3 color2 = vec3(0.0, 0.0, 0.1);
        vec3 color3 = vec3(0.0, 0.05, 0.3);
        return mix(mix(color1, color2, sin(t * 3.0) * 0.5 + 0.5), color3, cos(t * 2.0) * 0.5 + 0.5);
    }
    else if (layerIndex == 1) {
        // Shadow: Toxic greens
        vec3 color1 = vec3(0.0, 1.0, 0.0);
        vec3 color2 = vec3(0.8, 1.0, 0.0);
        vec3 color3 = vec3(0.0, 0.8, 0.3);
        return mix(mix(color1, color2, sin(t * 7.0) * 0.5 + 0.5), color3, cos(t * 5.0) * 0.5 + 0.5);
    }
    else if (layerIndex == 2) {
        // Content: Blazing hot
        vec3 color1 = vec3(1.0, 0.0, 0.0);
        vec3 color2 = vec3(1.0, 0.5, 0.0);
        vec3 color3 = vec3(1.0, 1.0, 1.0);
        return mix(mix(color1, color2, sin(t * 11.0) * 0.5 + 0.5), color3, cos(t * 8.0) * 0.5 + 0.5);
    }
    else if (layerIndex == 3) {
        // Highlight: Electric blues
        vec3 color1 = vec3(0.0, 1.0, 1.0);
        vec3 color2 = vec3(0.0, 0.5, 1.0);
        vec3 color3 = vec3(0.5, 1.0, 1.0);
        return mix(mix(color1, color2, sin(t * 13.0) * 0.5 + 0.5), color3, cos(t * 9.0) * 0.5 + 0.5);
    }
    else {
        // Accent: Violent magentas
        vec3 color1 = vec3(1.0, 0.0, 1.0);
        vec3 color2 = vec3(0.8, 0.0, 1.0);
        vec3 color3 = vec3(1.0, 0.3, 1.0);
        return mix(mix(color1, color2, sin(t * 17.0) * 0.5 + 0.5), color3, cos(t * 12.0) * 0.5 + 0.5);
    }
}

void main() {
    vec2 uv = (FlutterFragCoord().xy - u_resolution.xy * 0.5) / min(u_resolution.x, u_resolution.y);

    float timeSpeed = u_time * 0.0001 * u_speed;
    vec4 pos = vec4(uv * 3.0, sin(timeSpeed * 3.0), cos(timeSpeed * 2.0));
    pos.xy += (u_mouse - 0.5) * u_mouseIntensity * 2.0;

    pos = rotateXW(u_rot4dXW) * pos;
    pos = rotateYW(u_rot4dYW) * pos;
    pos = rotateZW(u_rot4dZW) * pos;

    int geomType = int(u_geometry);
    float value = geometryFunction(pos, geomType);

    float noise = sin(pos.x * 7.0) * cos(pos.y * 11.0) * sin(pos.z * 13.0);
    value += noise * u_chaos;

    float geometryIntensity = 1.0 - clamp(abs(value * 0.8), 0.0, 1.0);
    geometryIntensity = pow(geometryIntensity, 1.5);
    geometryIntensity += u_clickIntensity * 0.3;

    // Holographic shimmer
    float shimmer = sin(uv.x * 20.0 + timeSpeed * 5.0) * cos(uv.y * 15.0 + timeSpeed * 3.0) * 0.1;
    geometryIntensity += shimmer * geometryIntensity;

    float finalIntensity = geometryIntensity * u_intensity;

    int layerIndex = int(u_layerIndex);
    float colorTime = timeSpeed * 2.0 + value * 3.0 + u_hue / 360.0 * 5.0;
    vec3 layerColor = getLayerColorPalette(layerIndex, colorTime);

    // Layer-specific intensity modulation
    vec3 finalColor;
    if (layerIndex == 0) {
        finalColor = layerColor * (0.3 + geometryIntensity * 0.4);
    }
    else if (layerIndex == 1) {
        float shadowIntensity = pow(1.0 - geometryIntensity, 2.0);
        finalColor = layerColor * (shadowIntensity * 0.8 + 0.1);
    }
    else if (layerIndex == 2) {
        finalColor = layerColor * (geometryIntensity * 1.2 + 0.2);
    }
    else if (layerIndex == 3) {
        float peakIntensity = pow(geometryIntensity, 3.0);
        finalColor = layerColor * (peakIntensity * 1.5 + 0.1);
    }
    else {
        float randomBurst = sin(value * 50.0 + timeSpeed * 10.0) * 0.5 + 0.5;
        finalColor = layerColor * (randomBurst * geometryIntensity * 2.0 + 0.05);
    }

    // Layer alpha
    float layerAlpha;
    if (layerIndex == 0) layerAlpha = 0.6;
    else if (layerIndex == 1) layerAlpha = 0.4;
    else if (layerIndex == 2) layerAlpha = 1.0;
    else if (layerIndex == 3) layerAlpha = 0.8;
    else layerAlpha = 0.3;

    fragColor = vec4(finalColor, finalIntensity * layerAlpha);
}
