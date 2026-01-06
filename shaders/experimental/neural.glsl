// NEURAL: 5-Layer Bio-Digital Synaptic System
// Vibe: Brain scans, bioluminescence, organic circuitry
// Layers represent neural depth from cortex to deep brain
// ============================================================
vec3 renderNeural(vec2 uv, float geometryValue, vec4 pos) {
    float time = u_time * 0.001;
    vec3 finalColor = vec3(0.0);

    float geomIntensity = geometryValue;
    float pulse = sin(time * 4.0) * 0.5 + 0.5; // Neural rhythm
    float brainwaveAlpha = sin(time * 10.0) * 0.5 + 0.5; // Alpha waves ~10Hz

    // ============================================================
    // LAYER 0 - BACKGROUND: Neural substrate (dark tissue)
    // ============================================================
    {
        vec3 tissueColor = vec3(0.02, 0.04, 0.03); // Dark organic green
        vec3 fluidColor = vec3(0.01, 0.02, 0.04);  // Cerebrospinal fluid hint

        float tissueTex = sin(pos.x * 8.0) * sin(pos.y * 7.0) * sin(pos.z * 6.0);
        tissueTex = tissueTex * 0.5 + 0.5;

        vec3 layerColor = mix(tissueColor, fluidColor, tissueTex * 0.3);

        // Subtle blood vessel network
        float vessels = sin(uv.x * 30.0 + uv.y * 20.0) * sin(uv.y * 25.0 - uv.x * 15.0);
        vessels = smoothstep(0.7, 0.9, vessels) * 0.1;
        layerColor += vec3(0.15, 0.02, 0.02) * vessels;

        finalColor += layerColor * 0.5;
    }

    // ============================================================
    // LAYER 1 - SHADOW: Dormant neural pathways
    // ============================================================
    {
        vec3 dormantColor = vec3(0.05, 0.08, 0.15); // Dim blue-gray

        // Dendritic branching pattern - unrolled for mobile GPU compatibility
        float branch = 0.0;
        vec2 branchUV = uv * 15.0;
        {
            // Iteration 0 (i=0): divisor 1.0
            branchUV = abs(branchUV) - 0.5;
            branchUV *= 1.5;
            float d0 = length(branchUV) - 0.3;
            branch += (1.0 - smoothstep(0.0, 0.1, abs(d0))) / 1.0;

            // Iteration 1 (i=1): divisor 2.0
            branchUV = abs(branchUV) - 0.5;
            branchUV *= 1.5;
            float d1 = length(branchUV) - 0.3;
            branch += (1.0 - smoothstep(0.0, 0.1, abs(d1))) / 2.0;

            // Iteration 2 (i=2): divisor 3.0
            branchUV = abs(branchUV) - 0.5;
            branchUV *= 1.5;
            float d2 = length(branchUV) - 0.3;
            branch += (1.0 - smoothstep(0.0, 0.1, abs(d2))) / 3.0;
        }

        float dormancy = (1.0 - geomIntensity) * branch;
        vec3 layerColor = dormantColor * dormancy;

        finalColor += layerColor * 0.4;
    }

    // ============================================================
    // LAYER 2 - CONTENT: Active synapses (main neural activity)
    // ============================================================
    {
        float hue = u_hue / 360.0;
        vec3 synapseColor = hsv2rgb(vec3(hue + 0.5, 0.7, 0.6)); // Teal/cyan base
        vec3 activeColor = vec3(0.2, 0.8, 0.9);  // Bioluminescent cyan

        // Synaptic activity follows geometry
        float activity = geomIntensity * (0.7 + u_bassEnergy * 0.5);

        // Propagating waves
        float wave = sin(length(uv) * 20.0 - time * 8.0);
        wave = smoothstep(0.0, 0.3, wave) * smoothstep(0.6, 0.3, wave);
        activity += wave * 0.3 * geomIntensity;

        vec3 layerColor = mix(synapseColor, activeColor, activity);
        layerColor *= activity;

        // Synaptic vesicle glow
        float vesicles = pow(geomIntensity, 2.0) * brainwaveAlpha;
        layerColor += activeColor * vesicles * 0.4;

        finalColor += layerColor * 0.9;
    }

    // ============================================================
    // LAYER 3 - HIGHLIGHT: Firing neurons (action potentials)
    // ============================================================
    {
        vec3 firingColor = vec3(1.0, 0.95, 0.7);  // Bright yellow-white
        vec3 potentialColor = vec3(0.9, 0.6, 1.0); // Membrane potential purple

        // Action potential spikes
        float spike = pow(geomIntensity, 5.0);
        spike *= pulse; // Rhythmic firing
        spike *= (1.0 + u_highEnergy * 1.5); // Audio triggers spikes

        vec3 layerColor = mix(potentialColor, firingColor, spike);
        layerColor *= spike * 2.0;

        // Propagation trail
        float trail = sin(geomIntensity * 30.0 - time * 15.0);
        trail = max(trail, 0.0) * geomIntensity;
        layerColor += firingColor * trail * 0.3;

        finalColor += layerColor * 0.8;
    }

    // ============================================================
    // LAYER 4 - ACCENT: Signal propagation (neurotransmitter release)
    // ============================================================
    {
        vec3 dopamineColor = vec3(1.0, 0.3, 0.5);   // Pink/red (reward)
        vec3 serotoninColor = vec3(0.3, 1.0, 0.5);  // Green (mood)
        vec3 glutamateColor = vec3(1.0, 0.8, 0.2);  // Yellow (excitatory)

        // Neurotransmitter release bursts
        float release = pow(geomIntensity, 3.0) * (0.5 + pulse * 0.5);

        // Different transmitters cycle
        float transmitterPhase = fract(time * 0.3);
        vec3 transmitter = dopamineColor;
        transmitter = mix(transmitter, serotoninColor, smoothstep(0.33, 0.34, transmitterPhase));
        transmitter = mix(transmitter, glutamateColor, smoothstep(0.66, 0.67, transmitterPhase));

        vec3 layerColor = transmitter * release;

        // Diffusion effect
        float diffuse = exp(-length(uv) * 3.0) * release;
        layerColor += transmitter * diffuse * 0.5;

        // Audio modulation
        layerColor *= (0.4 + u_midEnergy * 1.2);

        finalColor += layerColor * 0.5;
    }

    // Organic pulsing
    finalColor *= (0.9 + brainwaveAlpha * 0.2);

    return finalColor * u_brightness;
}

// ============================================================
// PLASMA: 5-Layer Fusion Energy Containment System
// Vibe: Tokamak reactor, ball lightning, raw power
// Layers represent containment field depth and plasma density
