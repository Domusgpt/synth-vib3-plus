// PLASMA: 5-Layer Fusion Energy Containment System
// Vibe: Tokamak reactor, ball lightning, raw power
// Layers represent containment field depth and plasma density
// ============================================================
vec3 renderPlasma(vec2 uv, float geometryValue, vec4 pos) {
    float time = u_time * 0.002;
    vec3 finalColor = vec3(0.0);

    float geomIntensity = geometryValue;
    float instability = sin(time * 20.0 + length(uv) * 10.0) * 0.5 + 0.5;

    // ============================================================
    // LAYER 0 - BACKGROUND: Vacuum containment vessel
    // ============================================================
    {
        vec3 vesselColor = vec3(0.02, 0.02, 0.05); // Dark blue-black
        vec3 fieldColor = vec3(0.05, 0.02, 0.1);   // Magnetic field purple

        // Containment field grid
        float gridX = smoothstep(0.48, 0.5, fract(uv.x * 20.0));
        float gridY = smoothstep(0.48, 0.5, fract(uv.y * 20.0));
        float grid = max(gridX, gridY) * 0.3;

        vec3 layerColor = vesselColor + fieldColor * grid;

        // Magnetic field lines
        float fieldLine = sin(atan(uv.y, uv.x) * 8.0 + time * 2.0);
        fieldLine = smoothstep(0.9, 1.0, fieldLine) * 0.2;
        layerColor += vec3(0.2, 0.1, 0.4) * fieldLine;

        finalColor += layerColor * 0.5;
    }

    // ============================================================
    // LAYER 1 - SHADOW: Magnetic confinement field
    // ============================================================
    {
        vec3 fieldColor = vec3(0.15, 0.05, 0.3); // Purple magnetic field

        // Toroidal field pattern
        float toroidal = sin(atan(uv.y, uv.x) * 12.0 - time * 4.0);
        float poloidal = sin(length(uv) * 15.0 + time * 3.0);
        float field = (toroidal + poloidal) * 0.5 + 0.5;
        field *= (1.0 - geomIntensity); // Stronger where plasma is weak

        vec3 layerColor = fieldColor * field;

        // Field stress visualization
        float stress = abs(sin(uv.x * 30.0 + time * 10.0) * sin(uv.y * 25.0 - time * 8.0));
        layerColor += vec3(0.4, 0.1, 0.5) * stress * 0.2;

        finalColor += layerColor * 0.6;
    }

    // ============================================================
    // LAYER 2 - CONTENT: Plasma core (superheated matter)
    // ============================================================
    {
        float hue = u_hue / 360.0;

        // Plasma temperature gradient (cool edge to hot core)
        vec3 coolPlasma = vec3(1.0, 0.3, 0.1);    // Orange edge
        vec3 hotPlasma = vec3(1.0, 0.9, 0.5);     // Yellow-white core
        vec3 superhotPlasma = vec3(0.8, 0.9, 1.0); // Blue-white fusion

        float temp = geomIntensity * (1.0 + u_bassEnergy * 0.5);
        vec3 plasma = mix(coolPlasma, hotPlasma, temp);
        plasma = mix(plasma, superhotPlasma, pow(temp, 3.0));

        // Apply hue rotation
        plasma = mix(plasma, hsv2rgb(vec3(hue, 0.6, 0.9)), 0.2);

        // Plasma turbulence
        float turbulence = sin(pos.x * 10.0 + time * 15.0) *
                          sin(pos.y * 8.0 - time * 12.0) *
                          sin(pos.z * 12.0 + time * 10.0);
        turbulence = turbulence * 0.3 + 0.7;

        vec3 layerColor = plasma * temp * turbulence;

        // Instability ripples
        float ripple = sin(length(uv) * 30.0 - time * 20.0);
        ripple = max(ripple, 0.0) * instability * 0.3;
        layerColor += hotPlasma * ripple;

        finalColor += layerColor;
    }

    // ============================================================
    // LAYER 3 - HIGHLIGHT: Fusion reaction points
    // ============================================================
    {
        vec3 fusionColor = vec3(1.0, 1.0, 1.0);   // Pure white fusion
        vec3 gammaColor = vec3(0.7, 0.8, 1.0);    // Blue-shifted gamma

        // Fusion events at geometry peaks
        float fusion = pow(geomIntensity, 6.0);
        fusion *= (1.0 + u_highEnergy * 2.0);

        // Random fusion bursts
        float burst = step(0.98, fract(sin(dot(uv + time, vec2(12.9898, 78.233))) * 43758.5453));
        fusion += burst * 0.5;

        vec3 layerColor = mix(gammaColor, fusionColor, fusion);
        layerColor *= fusion * 3.0;

        // Gamma ray emission
        float gamma = pow(fusion, 2.0);
        layerColor += vec3(0.8, 0.9, 1.0) * gamma * 0.5;

        finalColor += layerColor * 0.7;
    }

    // ============================================================
    // LAYER 4 - ACCENT: Arc discharges and plasma jets
    // ============================================================
    {
        vec3 arcColor = vec3(0.4, 0.6, 1.0);      // Electric blue
        vec3 dischargeColor = vec3(0.8, 0.5, 1.0); // Purple discharge

        // Lightning arc pattern - unrolled for mobile GPU compatibility
        float arc = 0.0;
        vec2 arcUV = uv * 5.0;
        {
            // Iteration 0 (i=0): offset uses 0.0, divisor 1.0
            float offset0 = sin(time * 30.0 + 0.0 * 1.5) * 0.3;
            float arcLine0 = abs(arcUV.y - sin(arcUV.x * 3.0 + offset0 + 0.0) * 0.5);
            arc += (1.0 - smoothstep(0.0, 0.05, arcLine0)) / 1.0;
            arcUV = arcUV.yx * 1.2;

            // Iteration 1 (i=1): offset uses 1.5, divisor 2.0
            float offset1 = sin(time * 30.0 + 1.0 * 1.5) * 0.3;
            float arcLine1 = abs(arcUV.y - sin(arcUV.x * 3.0 + offset1 + 1.0) * 0.5);
            arc += (1.0 - smoothstep(0.0, 0.05, arcLine1)) / 2.0;
            arcUV = arcUV.yx * 1.2;

            // Iteration 2 (i=2): offset uses 3.0, divisor 3.0
            float offset2 = sin(time * 30.0 + 2.0 * 1.5) * 0.3;
            float arcLine2 = abs(arcUV.y - sin(arcUV.x * 3.0 + offset2 + 2.0) * 0.5);
            arc += (1.0 - smoothstep(0.0, 0.05, arcLine2)) / 3.0;
            arcUV = arcUV.yx * 1.2;

            // Iteration 3 (i=3): offset uses 4.5, divisor 4.0
            float offset3 = sin(time * 30.0 + 3.0 * 1.5) * 0.3;
            float arcLine3 = abs(arcUV.y - sin(arcUV.x * 3.0 + offset3 + 3.0) * 0.5);
            arc += (1.0 - smoothstep(0.0, 0.05, arcLine3)) / 4.0;
            arcUV = arcUV.yx * 1.2;
        }
        arc *= instability * geomIntensity;

        // Plasma jet ejection
        float jet = pow(abs(uv.y), 0.5) * geomIntensity;
        jet *= step(0.8, geomIntensity); // Only at high intensity

        vec3 layerColor = arcColor * arc;
        layerColor += dischargeColor * jet;

        // Audio-reactive arcing
        layerColor *= (0.3 + u_midEnergy * 1.5);

        finalColor += layerColor * 0.6;
    }

    // Containment field glow at edges
    float containment = smoothstep(0.6, 0.8, length(uv));
    finalColor = mix(finalColor, vec3(0.2, 0.1, 0.4), containment * 0.5);

    // Power surge effect
    finalColor *= (0.8 + instability * 0.4);

    return finalColor * u_brightness;
