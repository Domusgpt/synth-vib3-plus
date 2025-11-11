/**
 * VIB3+ Viewer Portal
 * Immersive full-screen visualization with Device Orientation API
 * Supports 3 systems with 6D rotation and card bending effects
 */

export class ViewerPortal {
    constructor(engine) {
        this.engine = engine;
        this.portalContainer = null;
        this.portalWindow = null;

        // Interactivity state
        this.interactivity = {
            mouse: true,
            tilt: true,
            enhanced: true
        };

        // Mouse tracking
        this.mouseX = 0.5;
        this.mouseY = 0.5;
        this.mouseIntensity = 0.0;
        this.isExpanded = false;

        // Device orientation tracking
        this.deviceOrientation = {
            alpha: 0,   // Z-axis (compass)
            beta: 0,    // X-axis (front-back tilt)
            gamma: 0    // Y-axis (left-right tilt)
        };

        // Base 6D rotations (from current engine state)
        this.baseRotations = {};

        // Card bending state
        this.tiltX = 0;
        this.tiltY = 0;
    }

    /**
     * Initialize viewer portal
     */
    async initialize(containerId = 'viewer-portal-container') {
        console.log('🎭 Initializing VIB3+ Viewer Portal');

        this.portalContainer = document.getElementById(containerId);
        if (!this.portalContainer) {
            console.error('❌ Portal container not found:', containerId);
            return false;
        }

        this.createPortalStructure();
        this.setupInteractivity();
        this.setupDeviceOrientation();
        this.setupControlPanel();

        // Store base rotations from current engine state
        const params = this.engine.getAllParameters();
        this.baseRotations = {
            rot4dXY: params.rot4dXY || 0,
            rot4dXZ: params.rot4dXZ || 0,
            rot4dYZ: params.rot4dYZ || 0,
            rot4dXW: params.rot4dXW || 0,
            rot4dYW: params.rot4dYW || 0,
            rot4dZW: params.rot4dZW || 0
        };

        console.log('✅ Viewer Portal initialized');
        return true;
    }

    /**
     * Create portal HTML structure
     */
    createPortalStructure() {
        this.portalContainer.innerHTML = `
            <div class="portal-viewer">
                <div class="silicon-background"></div>
                <div class="visualization-portal" id="portalWindow">
                    <div class="canvas-container" id="portal-canvas-container">
                        <!-- Engine canvases will be moved here -->
                    </div>
                </div>

                <div class="info-display" id="portalInfo">
                    <h3>Portal Parameters</h3>
                    <p id="portalSystemType">System: Loading...</p>
                    <p id="portalGeometry">Geometry: Loading...</p>
                    <p id="portalRotation">6D Rotation Active</p>
                </div>
            </div>
        `;

        this.portalWindow = document.getElementById('portalWindow');

        // Move engine canvas container into portal
        const engineContainer = document.getElementById('vib3-container');
        const portalCanvasContainer = document.getElementById('portal-canvas-container');

        if (engineContainer && portalCanvasContainer) {
            // Move all canvas layers to portal
            while (engineContainer.firstChild) {
                portalCanvasContainer.appendChild(engineContainer.firstChild);
            }
        }

        this.updatePortalInfo();
    }

    /**
     * Setup mouse/touch interactivity
     */
    setupInteractivity() {
        // Mouse move for parallax and card bending
        this.portalWindow.addEventListener('mousemove', (e) => {
            if (!this.interactivity.mouse) return;

            const rect = this.portalWindow.getBoundingClientRect();
            this.mouseX = (e.clientX - rect.left) / rect.width;
            this.mouseY = 1 - (e.clientY - rect.top) / rect.height;

            // Calculate card bending
            const centerX = rect.width / 2;
            const centerY = rect.height / 2;
            const maxTilt = this.isExpanded ? 25 : 10;

            this.tiltX = ((e.clientX - rect.left - centerX) / centerX) * maxTilt;
            this.tiltY = ((e.clientY - rect.top - centerY) / centerY) * -maxTilt;

            this.updateCardBending();

            if (this.interactivity.enhanced) {
                this.updateMouse6DPerspective();
            }
        });

        // Hover expansion
        this.portalWindow.addEventListener('mouseenter', () => {
            this.isExpanded = true;
            this.mouseIntensity = 1.0;
        });

        this.portalWindow.addEventListener('mouseleave', () => {
            this.isExpanded = false;
            this.mouseIntensity = 0.0;
            this.tiltX = 0;
            this.tiltY = 0;
            this.updateCardBending();
        });

        // Touch support
        this.portalWindow.addEventListener('touchmove', (e) => {
            if (!this.interactivity.mouse || e.touches.length === 0) return;

            e.preventDefault();
            const touch = e.touches[0];
            const rect = this.portalWindow.getBoundingClientRect();

            this.mouseX = (touch.clientX - rect.left) / rect.width;
            this.mouseY = 1 - (touch.clientY - rect.top) / rect.height;

            if (this.interactivity.enhanced) {
                this.updateMouse6DPerspective();
            }
        });

        // Keyboard shortcuts
        window.addEventListener('keydown', (e) => {
            if (e.key === 'f' || e.key === 'F') {
                this.toggleFullscreen();
            }
            if (e.key === 'Escape' && this.portalContainer.classList.contains('active')) {
                this.close();
            }
        });
    }

    /**
     * Setup Device Orientation API for mobile tilt
     */
    setupDeviceOrientation() {
        if (window.DeviceOrientationEvent) {
            // iOS 13+ requires permission
            if (typeof DeviceOrientationEvent.requestPermission === 'function') {
                // Will request permission when tilt is enabled
                console.log('📱 Device orientation requires permission (iOS 13+)');
            } else {
                // Android and older iOS - direct access
                window.addEventListener('deviceorientation', (e) => {
                    if (this.interactivity.tilt) {
                        this.handleDeviceOrientation(e);
                    }
                });
                console.log('📱 Device orientation enabled');
            }
        } else {
            console.log('📱 Device orientation not supported');
        }
    }

    /**
     * Handle device orientation events
     */
    handleDeviceOrientation(event) {
        this.deviceOrientation.alpha = event.alpha || 0;
        this.deviceOrientation.beta = event.beta || 0;
        this.deviceOrientation.gamma = event.gamma || 0;

        this.update6DPerspectiveFromTilt();
    }

    /**
     * Update 6D rotation based on device tilt
     */
    update6DPerspectiveFromTilt() {
        if (!this.interactivity.tilt) return;

        // Normalize tilt values
        const betaNorm = Math.max(-120, Math.min(120, this.deviceOrientation.beta));
        const gammaNorm = Math.max(-120, Math.min(120, this.deviceOrientation.gamma));
        const alphaNorm = ((this.deviceOrientation.alpha % 360) + 360) % 360;

        // Calculate tilt intensity for dramatic effects
        const tiltIntensity = Math.sqrt(betaNorm * betaNorm + gammaNorm * gammaNorm) / 90;
        const extremeTilt = tiltIntensity > 1.0;

        // Parallax background movement
        const parallaxMultiplier = extremeTilt ? 12 : 8;
        const bgOffsetX = -gammaNorm * parallaxMultiplier;
        const bgOffsetY = -betaNorm * (parallaxMultiplier * 0.75);
        const bgScale = 1.2 + tiltIntensity * 0.15;
        const bgRotation = alphaNorm * 0.3;
        const bgBlur = extremeTilt ? tiltIntensity * 2 : 0;

        // Apply background transforms
        document.documentElement.style.setProperty('--bg-offset-x', `${bgOffsetX}px`);
        document.documentElement.style.setProperty('--bg-offset-y', `${bgOffsetY}px`);
        document.documentElement.style.setProperty('--bg-scale', bgScale);
        document.documentElement.style.setProperty('--bg-rotation', `${bgRotation}deg`);
        document.documentElement.style.setProperty('--bg-blur', `${bgBlur}px`);

        // Card bending counter-rotation
        const counterMultiplier = extremeTilt ? 1.2 : 0.8;
        const counterRotateX = -betaNorm * counterMultiplier;
        const counterRotateY = -gammaNorm * counterMultiplier;
        const counterRotateZ = -alphaNorm * 0.4;
        const dynamicPerspective = 800 + tiltIntensity * 400;
        const portalScale = (this.isExpanded ? 1.08 : 1.0) + (extremeTilt ? tiltIntensity * 0.1 : 0);
        const portalTranslateZ = (this.isExpanded ? 30 : 0) + (extremeTilt ? tiltIntensity * 20 : 0);

        // Apply card bending
        this.portalWindow.style.transform = `
            perspective(${dynamicPerspective}px)
            rotateX(${counterRotateX}deg)
            rotateY(${counterRotateY}deg)
            rotateZ(${counterRotateZ}deg)
            scale(${portalScale})
            translateZ(${portalTranslateZ}px)
        `;

        // **DRAMATIC 6D ROTATION TRANSFORMATION**
        const dramatic6DScale = extremeTilt ? 0.8 : 0.5;
        const transformativeScale = tiltIntensity * 0.2;

        const perspective6D = {
            // 6D rotation mapped from device tilt
            rot4dXY: this.baseRotations.rot4dXY + (gammaNorm * Math.PI / 180 * dramatic6DScale * 0.5),
            rot4dXZ: this.baseRotations.rot4dXZ + (betaNorm * Math.PI / 180 * dramatic6DScale * 0.5),
            rot4dYZ: this.baseRotations.rot4dYZ + (alphaNorm * Math.PI / 180 * dramatic6DScale * 0.3),
            rot4dXW: this.baseRotations.rot4dXW + (betaNorm * Math.PI / 180 * dramatic6DScale),
            rot4dYW: this.baseRotations.rot4dYW + (gammaNorm * Math.PI / 180 * dramatic6DScale),
            rot4dZW: this.baseRotations.rot4dZW + (alphaNorm * Math.PI / 180 * dramatic6DScale * 0.5),

            // Transformative effects
            morphFactor: this.engine.getParameter('morphFactor') + tiltIntensity * 0.4 + transformativeScale,
            intensity: this.engine.getParameter('intensity') + tiltIntensity * 0.25 + (extremeTilt ? 0.2 : 0),
            chaos: this.engine.getParameter('chaos') + Math.pow(tiltIntensity, 2) * 0.15,
            gridDensity: this.engine.getParameter('gridDensity') * (1 + tiltIntensity * 0.3),
            hue: (this.engine.getParameter('hue') + (alphaNorm - 180) * 0.8 + (extremeTilt ? Math.sin(Date.now() * 0.005) * 20 : 0)) % 360,
            saturation: this.engine.getParameter('saturation') + tiltIntensity * 0.15 + (extremeTilt ? 0.1 : 0)
        };

        // Apply to engine
        this.engine.setParameters(perspective6D);

        // Visual feedback
        document.documentElement.style.setProperty('--tilt-intensity', tiltIntensity);

        // Extreme tilt glow effects
        if (extremeTilt) {
            const glowIntensity = (tiltIntensity - 1) * 3;
            const pulseSpeed = Math.max(0.5, 2 - tiltIntensity * 0.5);
            document.documentElement.style.setProperty('--extreme-glow', glowIntensity);
            document.documentElement.style.setProperty('--pulse-speed', `${pulseSpeed}s`);

            this.portalWindow.style.boxShadow = `
                0 0 ${glowIntensity * 20}px rgba(0, 255, 204, ${glowIntensity * 0.3}),
                0 0 ${glowIntensity * 40}px rgba(255, 0, 255, ${glowIntensity * 0.2}),
                inset 0 0 ${glowIntensity * 10}px rgba(255, 255, 255, ${glowIntensity * 0.1})
            `;

            // Haptic feedback
            if ('vibrate' in navigator) {
                navigator.vibrate(Math.floor(tiltIntensity * 50));
            }
        } else {
            document.documentElement.style.setProperty('--extreme-glow', 0);
            this.portalWindow.style.boxShadow = '';
        }
    }

    /**
     * Update 6D perspective based on mouse movement
     */
    updateMouse6DPerspective() {
        const mouseOffsetX = (this.mouseX - 0.5) * 2; // -1 to 1
        const mouseOffsetY = (this.mouseY - 0.5) * 2; // -1 to 1

        // Parallax background (if not using tilt)
        if (!this.interactivity.tilt) {
            const bgMouseX = -mouseOffsetX * 30;
            const bgMouseY = -mouseOffsetY * 20;
            document.documentElement.style.setProperty('--bg-offset-x', `${bgMouseX}px`);
            document.documentElement.style.setProperty('--bg-offset-y', `${bgMouseY}px`);
        }

        // Subtle 6D perspective changes
        const mouse6DScale = 0.15;

        const mouse6D = {
            rot4dXY: this.baseRotations.rot4dXY + (mouseOffsetX * mouse6DScale * 0.3),
            rot4dXZ: this.baseRotations.rot4dXZ + (mouseOffsetY * mouse6DScale * 0.3),
            rot4dYZ: this.baseRotations.rot4dYZ,
            rot4dXW: this.baseRotations.rot4dXW + (mouseOffsetY * mouse6DScale),
            rot4dYW: this.baseRotations.rot4dYW + (mouseOffsetX * mouse6DScale),
            rot4dZW: this.baseRotations.rot4dZW,

            // Slight morph based on distance from center
            morphFactor: this.engine.getParameter('morphFactor') +
                        (Math.sqrt(mouseOffsetX * mouseOffsetX + mouseOffsetY * mouseOffsetY) * 0.05)
        };

        // Combine with tilt if active
        if (this.interactivity.tilt) {
            const betaNorm = Math.max(-90, Math.min(90, this.deviceOrientation.beta));
            const gammaNorm = Math.max(-90, Math.min(90, this.deviceOrientation.gamma));
            const alpha = this.deviceOrientation.alpha;

            mouse6D.rot4dXY += (gammaNorm * Math.PI / 180 * 0.05);
            mouse6D.rot4dXZ += (betaNorm * Math.PI / 180 * 0.05);
            mouse6D.rot4dXW += (betaNorm * Math.PI / 180 * 0.1);
            mouse6D.rot4dYW += (gammaNorm * Math.PI / 180 * 0.1);
            mouse6D.rot4dZW += (alpha * Math.PI / 180 * 0.05);
        }

        this.engine.setParameters(mouse6D);
    }

    /**
     * Update card bending transform
     */
    updateCardBending() {
        if (!this.interactivity.mouse || this.interactivity.tilt) return;

        const existingScale = this.isExpanded ? 1.08 : 1.0;
        const existingZ = this.isExpanded ? 30 : 0;

        this.portalWindow.style.transform = `
            perspective(1000px)
            rotateX(${this.tiltY}deg)
            rotateY(${this.tiltX}deg)
            scale(${existingScale})
            translateZ(${existingZ}px)
        `;
    }

    /**
     * Setup control panel
     */
    setupControlPanel() {
        const controlPanel = document.createElement('div');
        controlPanel.className = 'portal-control-panel';
        controlPanel.innerHTML = `
            <button class="portal-control-btn active" id="portal-mouse-toggle">Mouse Reactive</button>
            <button class="portal-control-btn active" id="portal-tilt-toggle">Device Tilt</button>
            <button class="portal-control-btn active" id="portal-enhanced-toggle">Enhanced FX</button>
            <hr style="border: 1px solid rgba(0, 255, 204, 0.3); margin: 6px 0;">
            <button class="portal-control-btn" id="portal-share">Share Portal</button>
            <button class="portal-control-btn" id="portal-export-card">Export Card</button>
            <button class="portal-control-btn" id="portal-close">Close Portal</button>
        `;

        this.portalContainer.appendChild(controlPanel);

        // Event handlers
        document.getElementById('portal-mouse-toggle').addEventListener('click', () => {
            this.toggleInteractivity('mouse');
        });

        document.getElementById('portal-tilt-toggle').addEventListener('click', () => {
            this.toggleInteractivity('tilt');
        });

        document.getElementById('portal-enhanced-toggle').addEventListener('click', () => {
            this.toggleInteractivity('enhanced');
        });

        document.getElementById('portal-share').addEventListener('click', () => {
            this.sharePortal();
        });

        document.getElementById('portal-export-card').addEventListener('click', () => {
            this.exportTradingCard();
        });

        document.getElementById('portal-close').addEventListener('click', () => {
            this.close();
        });
    }

    /**
     * Toggle interactivity mode
     */
    toggleInteractivity(type) {
        this.interactivity[type] = !this.interactivity[type];
        const button = document.getElementById(`portal-${type}-toggle`);

        if (this.interactivity[type]) {
            button.classList.add('active');
        } else {
            button.classList.remove('active');
        }

        // iOS 13+ device orientation permission
        if (type === 'tilt' && this.interactivity.tilt) {
            if (typeof DeviceOrientationEvent.requestPermission === 'function') {
                DeviceOrientationEvent.requestPermission().then(response => {
                    if (response === 'granted') {
                        window.addEventListener('deviceorientation', (e) => {
                            if (this.interactivity.tilt) {
                                this.handleDeviceOrientation(e);
                            }
                        });
                        console.log('📱 Device orientation permission granted');
                    }
                }).catch(console.error);
            }
        }

        // Reset rotations when tilt is disabled
        if (type === 'tilt' && !this.interactivity.tilt) {
            const baseParams = {};
            Object.keys(this.baseRotations).forEach(key => {
                baseParams[key] = this.baseRotations[key];
            });
            this.engine.setParameters(baseParams);
        }

        console.log(`🎭 Portal ${type}: ${this.interactivity[type] ? 'ON' : 'OFF'}`);
    }

    /**
     * Share portal with current state
     */
    sharePortal() {
        const state = this.engine.exportState();
        const url = new URL(window.location.href);
        url.searchParams.set('config', JSON.stringify(state));

        const shareData = {
            title: 'VIB3+ Portal Visualization',
            text: 'Check out this amazing VIB3+ holographic visualization!',
            url: url.toString()
        };

        if (navigator.share) {
            navigator.share(shareData).catch(console.error);
        } else {
            navigator.clipboard.writeText(url.toString()).then(() => {
                alert('Portal link copied to clipboard!');
            });
        }
    }

    /**
     * Export as trading card image
     */
    async exportTradingCard() {
        console.log('📸 Exporting trading card...');

        // Create a canvas with the current visualization
        const canvas = document.createElement('canvas');
        canvas.width = 600;
        canvas.height = 800;
        const ctx = canvas.getContext('2d');

        // Draw background
        ctx.fillStyle = 'linear-gradient(135deg, #0a0a1a 0%, #1a1a2e 100%)';
        ctx.fillRect(0, 0, canvas.width, canvas.height);

        // Draw border
        ctx.strokeStyle = '#00ffcc';
        ctx.lineWidth = 4;
        ctx.strokeRect(10, 10, canvas.width - 20, canvas.height - 20);

        // Get current state info
        const state = this.engine.exportState();
        const system = state.system.toUpperCase();
        const geometryNames = this.engine.getGeometryNames();
        const geometry = geometryNames[state.parameters.geometry] || 'Unknown';

        // Draw text info
        ctx.fillStyle = '#00ffcc';
        ctx.font = 'bold 24px Arial';
        ctx.fillText('VIB3+ VISUALIZATION', 30, 50);

        ctx.font = '18px Arial';
        ctx.fillText(`System: ${system}`, 30, 750);
        ctx.fillText(`Geometry: ${geometry}`, 30, 775);

        // Download
        canvas.toBlob(blob => {
            const url = URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = url;
            link.download = `vib3plus-card-${Date.now()}.png`;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            URL.revokeObjectURL(url);

            console.log('✅ Trading card exported');
        });
    }

    /**
     * Toggle fullscreen
     */
    toggleFullscreen() {
        if (!document.fullscreenElement) {
            this.portalContainer.requestFullscreen().catch(console.error);
        } else {
            document.exitFullscreen();
        }
    }

    /**
     * Update portal info display
     */
    updatePortalInfo() {
        const state = this.engine.exportState();
        const systemNames = {
            quantum: '🌌 Quantum Engine',
            faceted: '🔷 Faceted System',
            holographic: '🌈 Holographic System'
        };
        const geometryNames = this.engine.getGeometryNames();

        document.getElementById('portalSystemType').textContent =
            `System: ${systemNames[state.system]}`;
        document.getElementById('portalGeometry').textContent =
            `Geometry: ${geometryNames[state.parameters.geometry] || 'Unknown'}`;
    }

    /**
     * Open viewer portal
     */
    open() {
        this.portalContainer.classList.add('active');
        this.updatePortalInfo();

        // Update base rotations
        const params = this.engine.getAllParameters();
        Object.keys(this.baseRotations).forEach(key => {
            this.baseRotations[key] = params[key] || 0;
        });

        console.log('🎭 Viewer Portal opened');
    }

    /**
     * Close viewer portal
     */
    close() {
        this.portalContainer.classList.remove('active');

        // Move canvases back to main container
        const portalCanvasContainer = document.getElementById('portal-canvas-container');
        const engineContainer = document.getElementById('vib3-container');

        if (portalCanvasContainer && engineContainer) {
            while (portalCanvasContainer.firstChild) {
                engineContainer.appendChild(portalCanvasContainer.firstChild);
            }
        }

        // Reset transforms
        document.documentElement.style.setProperty('--bg-offset-x', '0px');
        document.documentElement.style.setProperty('--bg-offset-y', '0px');
        document.documentElement.style.setProperty('--bg-scale', '1.0');
        document.documentElement.style.setProperty('--bg-rotation', '0deg');
        document.documentElement.style.setProperty('--bg-blur', '0px');

        console.log('🎭 Viewer Portal closed');
    }
}
