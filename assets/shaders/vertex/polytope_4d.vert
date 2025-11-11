#version 300 es

/**
 * VIB34D 4D Polytope Vertex Shader
 *
 * Renders 4D geometry with quaternion-based rotation across three 4D planes:
 * - XW plane rotation (controlled by Oscillator 1 Frequency)
 * - YW plane rotation (controlled by Oscillator 2 Frequency)
 * - ZW plane rotation (controlled by Filter Cutoff)
 *
 * Uses stereographic projection to convert 4D coordinates to 3D space.
 *
 * A Paul Phillips Manifestation
 */

precision highp float;

// Vertex attributes (4D position)
in vec4 a_position4d;  // (x, y, z, w)

// Uniforms
uniform mat4 u_projection;      // 3D projection matrix
uniform mat4 u_modelView;       // 3D model-view matrix

// 4D rotation angles (controlled by audio synthesis parameters)
uniform float u_rot4dXW;        // XW plane rotation → Oscillator 1 Frequency
uniform float u_rot4dYW;        // YW plane rotation → Oscillator 2 Frequency
uniform float u_rot4dZW;        // ZW plane rotation → Filter Cutoff

// Outputs to fragment shader
out vec3 v_position3d;
out float v_wCoord;             // W-coordinate for coloring
out vec3 v_normal;

// 4D Rotation Matrix: XW plane
mat4 rotation4D_XW(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat4(
        c,   0.0, 0.0, s,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        -s,  0.0, 0.0, c
    );
}

// 4D Rotation Matrix: YW plane
mat4 rotation4D_YW(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat4(
        1.0, 0.0, 0.0, 0.0,
        0.0, c,   0.0, s,
        0.0, 0.0, 1.0, 0.0,
        0.0, -s,  0.0, c
    );
}

// 4D Rotation Matrix: ZW plane
mat4 rotation4D_ZW(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat4(
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, c,   s,
        0.0, 0.0, -s,  c
    );
}

void main() {
    // Apply 4D rotations in sequence
    vec4 rotated4d = a_position4d;
    rotated4d = rotation4D_XW(u_rot4dXW) * rotated4d;
    rotated4d = rotation4D_YW(u_rot4dYW) * rotated4d;
    rotated4d = rotation4D_ZW(u_rot4dZW) * rotated4d;

    // Stereographic projection: 4D → 3D
    // Project from point at (0,0,0,w_offset) onto w=0 hyperplane
    float w_offset = 2.0;  // Distance from projection point
    float scale = w_offset / (w_offset - rotated4d.w);
    vec3 projected3d = rotated4d.xyz * scale;

    // Apply 3D transformations
    vec4 position3d = vec4(projected3d, 1.0);
    gl_Position = u_projection * u_modelView * position3d;

    // Calculate approximate normal (for lighting)
    v_normal = normalize(projected3d);

    // Pass to fragment shader
    v_position3d = projected3d;
    v_wCoord = rotated4d.w;
}
