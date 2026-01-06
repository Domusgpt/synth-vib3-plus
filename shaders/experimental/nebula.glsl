// NEBULA: 5-Layer Cosmic Deep Space System
// Vibe: Hubble telescope, cosmic dust, stellar nurseries
// Layer structure creates depth like looking through gas clouds
// ============================================================
vec3 renderNebula(vec2 uv, float geometryValue, vec4 pos) {
    float time = u_time * 0.0008; // Slower, more majestic
    vec3 finalColor = vec3(0.0);

    float geomIntensity = geometryValue;
    float cosmicTime = time + length(uv) * 0.5;

    // Star field background (tiny bright points) - unrolled for mobile GPU compatibility
    float stars = 0.0;
    {
        // Layer 0 (i=0): density 50
        vec2 starUV0 = uv * 50.0;
        vec2 starID0 = floor(starUV0);
        vec2 starPos0 = fract(starUV0) - 0.5;
        float starDist0 = length(starPos0);
        float starRand0 = fract(sin(dot(starID0, vec2(12.9898, 78.233))) * 43758.5453);
        float starBright0 = (1.0 - smoothstep(0.0, 0.03, starDist0)) * step(0.97, starRand0);
        stars += starBright0 * (0.5 + 0.5 * sin(time * 3.0 + starRand0 * 6.28));

        // Layer 1 (i=1): density 80
        vec2 starUV1 = uv * 80.0;
        vec2 starID1 = floor(starUV1);
        vec2 starPos1 = fract(starUV1) - 0.5;
        float starDist1 = length(starPos1);
        float starRand1 = fract(sin(dot(starID1, vec2(12.9898, 78.233))) * 43758.5453);
        float starBright1 = (1.0 - smoothstep(0.0, 0.03, starDist1)) * step(0.97, starRand1);
        stars += starBright1 * (0.5 + 0.5 * sin(time * 3.0 + starRand1 * 6.28));

        // Layer 2 (i=2): density 110
        vec2 starUV2 = uv * 110.0;
        vec2 starID2 = floor(starUV2);
        vec2 starPos2 = fract(starUV2) - 0.5;
        float starDist2 = length(starPos2);
        float starRand2 = fract(sin(dot(starID2, vec2(12.9898, 78.233))) * 43758.5453);
        float starBright2 = (1.0 - smoothstep(0.0, 0.03, starDist2)) * step(0.97, starRand2);
        stars += starBright2 * (0.5 + 0.5 * sin(time * 3.0 + starRand2 * 6.28));
    }

    // ============================================================
    // LAYER 0 - BACKGROUND: Deep space void with distant stars
    // ============================================================
    {
        vec3 voidColor = vec3(0.02, 0.01, 0.04); // Near black with purple tint
        vec3 dustColor = vec3(0.08, 0.02, 0.12); // Dark purple dust

        float dustNoise = sin(pos.x * 3.0 + time) * sin(pos.y * 2.5 - time * 0.5) * 0.5 + 0.5;
        vec3 layerColor = mix(voidColor, dustColor, dustNoise * 0.3);
        layerColor += vec3(1.0, 0.95, 0.8) * stars * 0.4; // Warm star light

        finalColor += layerColor * 0.6;
    }

    // ============================================================
    // LAYER 1 - SHADOW: Dark nebula dust clouds (absorption)
    // ============================================================
    {
        vec3 color1 = vec3(0.15, 0.02, 0.02); // Dark red/brown
        vec3 color2 = vec3(0.08, 0.04, 0.01); // Dark amber

        float cloudDensity = pow(1.0 - geomIntensity, 1.5);
        float cloudNoise = sin(pos.x * 5.0 + time * 0.3) * cos(pos.z * 4.0 - time * 0.2);
        cloudDensity *= (0.6 + cloudNoise * 0.4);

        vec3 layerColor = mix(color1, color2, sin(cosmicTime * 2.0) * 0.5 + 0.5);
        layerColor *= cloudDensity;

        // Dust occlusion effect
        finalColor = mix(finalColor, layerColor, cloudDensity * 0.5);
    }

    // ============================================================
    // LAYER 2 - CONTENT: Nebula emission (ionized gas glow)
    // ============================================================
    {
        // Classic nebula colors: H-alpha red, O-III teal, S-II orange
        float hue = u_hue / 360.0;
        vec3 emissionRed = vec3(0.9, 0.2, 0.3);    // Hydrogen alpha
        vec3 emissionTeal = vec3(0.1, 0.7, 0.6);   // Oxygen III
        vec3 emissionOrange = vec3(1.0, 0.5, 0.1); // Sulfur II

        float emissionMix = sin(cosmicTime * 3.0 + geomIntensity * 5.0) * 0.5 + 0.5;
        vec3 emission = mix(emissionRed, emissionTeal, emissionMix);
        emission = mix(emission, emissionOrange, sin(cosmicTime * 2.0 + 2.0) * 0.3 + 0.3);

        // Apply hue shift
        emission = mix(emission, hsv2rgb(vec3(hue, 0.8, 0.7)), 0.3);

        float emissionIntensity = geomIntensity * (0.8 + u_bassEnergy * 0.4);
        vec3 layerColor = emission * emissionIntensity;

        // Volumetric glow
        float glow = exp(-abs(geomIntensity - 0.5) * 4.0) * 0.5;
        layerColor += emission * glow;

        finalColor += layerColor * 0.9;
    }

    // ============================================================
    // LAYER 3 - HIGHLIGHT: Star formation regions (bright cores)
    // ============================================================
    {
        vec3 hotStarColor = vec3(0.8, 0.9, 1.0);  // Blue-white young stars
        vec3 protostar = vec3(1.0, 0.8, 0.4);     // Yellow protostars

        float coreIntensity = pow(geomIntensity, 4.0);
        coreIntensity *= (1.0 + u_highEnergy * 0.8);

        vec3 layerColor = mix(protostar, hotStarColor, coreIntensity);
        layerColor *= coreIntensity * 1.5;

        // Stellar wind effect
        float wind = sin(length(uv) * 20.0 - time * 5.0) * 0.5 + 0.5;
        layerColor += hotStarColor * wind * coreIntensity * 0.3;

        finalColor += layerColor * 0.8;
    }

    // ============================================================
    // LAYER 4 - ACCENT: Cosmic rays and high-energy jets
    // ============================================================
    {
        vec3 cosmicRayColor = vec3(0.6, 0.2, 1.0); // Violet/UV
        vec3 jetColor = vec3(0.3, 0.5, 1.0);       // Blue jets

        // Directional jets from geometry peaks
        float jetAngle = atan(uv.y, uv.x);
        float jetPattern = pow(abs(sin(jetAngle * 2.0 + time)), 8.0);
        float jetIntensity = geomIntensity * jetPattern * 2.0;

        // Cosmic ray streaks
        float rayStreak = sin(uv.x * 100.0 + uv.y * 50.0 + time * 20.0);
        rayStreak = pow(max(rayStreak, 0.0), 10.0) * 0.3;

        vec3 layerColor = cosmicRayColor * rayStreak;
        layerColor += jetColor * jetIntensity;

        // Pulsing with audio
        layerColor *= (0.5 + u_midEnergy * 1.0);

        finalColor += layerColor * 0.4;
    }

    // Cosmic dust scattering
    float scatter = length(uv) * 0.1;
    finalColor *= (1.0 - scatter * 0.3);

    return finalColor * u_brightness;
}

// ============================================================
// NEURAL: 5-Layer Bio-Digital Synaptic System
// Vibe: Brain scans, bioluminescence, organic circuitry
// Layers represent neural depth from cortex to deep brain
