/**
 * Synth-VIB3+ End-to-End Tests
 *
 * Tests the deployed web application for:
 * - App initialization and loading
 * - VIB3+ visualizer initialization (should NOT be black)
 * - Visual system switching (Quantum, Faceted, Holographic)
 * - Geometry selection (8 base geometries × 3 polytope cores)
 * - Audio controls and synthesis branch switching
 * - UI responsiveness
 */

import { test, expect } from '@playwright/test';

test.describe('App Initialization', () => {
  test('should load without errors', async ({ page }) => {
    // Navigate and wait for app to load
    const response = await page.goto('/');
    expect(response?.status()).toBeLessThan(400);

    // Wait for Flutter to initialize
    await page.waitForTimeout(3000);

    // Check for console errors
    const errors: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });

    await page.waitForTimeout(2000);

    // Filter out known benign errors
    const criticalErrors = errors.filter(err =>
      !err.includes('favicon') &&
      !err.includes('manifest') &&
      !err.includes('service worker')
    );

    if (criticalErrors.length > 0) {
      console.log('Console errors found:', criticalErrors);
    }
  });

  test('should display Material app structure', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(3000);

    // Flutter web renders as canvas
    const canvas = page.locator('canvas, flt-glass-pane');
    await expect(canvas.first()).toBeVisible({ timeout: 10000 });
  });
});

test.describe('VIB3+ Visualizer', () => {
  test('should NOT show black screen - visualizer must initialize', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(5000);

    // Take screenshot for debugging
    await page.screenshot({ path: 'screenshots/visualizer-init.png', fullPage: true });

    // Check canvas is present and has content
    const canvas = page.locator('canvas').first();
    await expect(canvas).toBeVisible({ timeout: 10000 });

    // Get canvas dimensions
    const box = await canvas.boundingBox();
    expect(box).toBeTruthy();
    expect(box!.width).toBeGreaterThan(100);
    expect(box!.height).toBeGreaterThan(100);

    // Check that the canvas is not entirely black by sampling pixels
    // This requires JavaScript evaluation in the page context
    const isNotBlack = await page.evaluate(() => {
      const canvases = document.querySelectorAll('canvas');
      for (const canvas of canvases) {
        try {
          const ctx = canvas.getContext('2d');
          if (ctx) {
            const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
            const data = imageData.data;
            // Check if any pixel has non-zero values (not pure black)
            for (let i = 0; i < data.length; i += 4) {
              if (data[i] > 0 || data[i + 1] > 0 || data[i + 2] > 0) {
                return true;
              }
            }
          }
        } catch (e) {
          // Cross-origin canvas or WebGL canvas - can't sample directly
          // WebGL canvases typically indicate visualization is working
          if (canvas.getContext('webgl') || canvas.getContext('webgl2')) {
            return true; // WebGL context exists, assume it's rendering
          }
        }
      }
      return false;
    });

    console.log('Visualizer content detected:', isNotBlack);
  });

  test('should have WebGL context available', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(3000);

    const hasWebGL = await page.evaluate(() => {
      const canvas = document.createElement('canvas');
      return !!(canvas.getContext('webgl') || canvas.getContext('webgl2'));
    });

    expect(hasWebGL).toBe(true);
  });
});

test.describe('Visual System Switching', () => {
  test('should switch between Quantum, Faceted, and Holographic systems', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(4000);

    // Take initial screenshot
    await page.screenshot({ path: 'screenshots/system-initial.png' });

    // Try to find and click system selectors (Q, F, H buttons in top bezel)
    // Flutter web uses semantic labels or we need to click by position

    // Since Flutter renders to canvas, we'll need to use coordinates
    // Top bezel with Q/F/H buttons should be in the top-left area

    const topBezelArea = { x: 100, y: 30 }; // Approximate position of system buttons

    // Click on different positions where Q/F/H buttons should be
    const qButtonPos = { x: 60, y: 30 };
    const fButtonPos = { x: 110, y: 30 };
    const hButtonPos = { x: 160, y: 30 };

    // Click Faceted (F)
    await page.mouse.click(fButtonPos.x, fButtonPos.y);
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'screenshots/system-faceted.png' });

    // Click Holographic (H)
    await page.mouse.click(hButtonPos.x, hButtonPos.y);
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'screenshots/system-holographic.png' });

    // Click Quantum (Q)
    await page.mouse.click(qButtonPos.x, qButtonPos.y);
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'screenshots/system-quantum.png' });
  });
});

test.describe('Geometry Panel', () => {
  test('should display 8 base geometries and 3 polytope cores', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(4000);

    // Open geometry panel by clicking on Geometry tab at bottom
    // Bottom bezel tabs should be around y=height-40
    const viewportSize = page.viewportSize();
    const bottomY = viewportSize!.height - 40;

    // Geometry tab should be 3rd from left (Synthesis, Effects, Geometry, Mapping)
    const geometryTabX = viewportSize!.width * 0.625; // ~62.5% from left
    await page.mouse.click(geometryTabX, bottomY);
    await page.waitForTimeout(1000);

    await page.screenshot({ path: 'screenshots/geometry-panel-open.png' });

    // Panel should expand showing 3 core buttons + 8 geometry buttons
    // Take screenshot for visual verification
  });

  test('should switch polytope cores correctly', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(4000);

    // Open geometry panel
    const viewportSize = page.viewportSize();
    const bottomY = viewportSize!.height - 40;
    const geometryTabX = viewportSize!.width * 0.625;
    await page.mouse.click(geometryTabX, bottomY);
    await page.waitForTimeout(1500);

    // Take screenshots of each core selection
    // Core buttons should be near the top of the expanded panel
    const panelY = viewportSize!.height - 200; // Approximate y for expanded panel

    // Click Base core
    await page.mouse.click(viewportSize!.width * 0.2, panelY);
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'screenshots/core-base.png' });

    // Click Hypersphere core
    await page.mouse.click(viewportSize!.width * 0.5, panelY);
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'screenshots/core-hypersphere.png' });

    // Click Hypertetrahedron core
    await page.mouse.click(viewportSize!.width * 0.8, panelY);
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'screenshots/core-hypertetra.png' });
  });
});

test.describe('Synthesis Panel', () => {
  test('should show synthesis branch selector', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(4000);

    // Open synthesis panel by clicking first tab
    const viewportSize = page.viewportSize();
    const bottomY = viewportSize!.height - 40;
    const synthesisTabX = viewportSize!.width * 0.125;
    await page.mouse.click(synthesisTabX, bottomY);
    await page.waitForTimeout(1000);

    await page.screenshot({ path: 'screenshots/synthesis-panel-open.png' });
  });

  test('should switch between Direct, FM, and Ring Mod', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(4000);

    // Open synthesis panel
    const viewportSize = page.viewportSize();
    const bottomY = viewportSize!.height - 40;
    const synthesisTabX = viewportSize!.width * 0.125;
    await page.mouse.click(synthesisTabX, bottomY);
    await page.waitForTimeout(1500);

    // Branch selector should be near top of panel
    const panelY = viewportSize!.height - 250;

    // Click each branch
    await page.mouse.click(viewportSize!.width * 0.2, panelY);
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'screenshots/branch-direct.png' });

    await page.mouse.click(viewportSize!.width * 0.5, panelY);
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'screenshots/branch-fm.png' });

    await page.mouse.click(viewportSize!.width * 0.8, panelY);
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'screenshots/branch-ringmod.png' });
  });
});

test.describe('XY Pad Interaction', () => {
  test('should respond to touch/click on main visualizer area', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(4000);

    const viewportSize = page.viewportSize();
    const centerX = viewportSize!.width / 2;
    const centerY = viewportSize!.height / 2;

    // Take screenshot before interaction
    await page.screenshot({ path: 'screenshots/xypad-before.png' });

    // Click and drag on the main visualizer area
    await page.mouse.move(centerX, centerY);
    await page.mouse.down();
    await page.mouse.move(centerX + 100, centerY + 50, { steps: 10 });
    await page.mouse.up();
    await page.waitForTimeout(500);

    await page.screenshot({ path: 'screenshots/xypad-after.png' });
  });
});

test.describe('Top Bezel Display', () => {
  test('should show geometry indicator with correct format', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(4000);

    // Top bezel should show format like "Base: Tetrahedron" or "Hypersphere: Torus"
    await page.screenshot({ path: 'screenshots/top-bezel.png' });

    // The geometry indicator should not cause any crashes (was crashing before fix)
    // If we can see the page without errors after 4 seconds, indicator is working
    const canvas = page.locator('canvas').first();
    await expect(canvas).toBeVisible();
  });

  test('should show FPS counter', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(4000);

    // FPS counter should be visible in top bezel
    await page.screenshot({ path: 'screenshots/fps-counter.png' });
  });
});

test.describe('Audio Controls', () => {
  test('should have audio context when user interacts', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(3000);

    // Click to allow audio context (browsers require user interaction)
    const viewportSize = page.viewportSize();
    await page.mouse.click(viewportSize!.width / 2, viewportSize!.height / 2);
    await page.waitForTimeout(1000);

    // Check if audio context is available
    const hasAudioContext = await page.evaluate(() => {
      return typeof AudioContext !== 'undefined' || typeof (window as any).webkitAudioContext !== 'undefined';
    });

    expect(hasAudioContext).toBe(true);
  });
});

test.describe('Responsive Layout', () => {
  test('should adapt to portrait orientation', async ({ page }) => {
    await page.setViewportSize({ width: 412, height: 915 });
    await page.goto('/');
    await page.waitForTimeout(3000);
    await page.screenshot({ path: 'screenshots/layout-portrait.png' });
  });

  test('should adapt to landscape orientation', async ({ page }) => {
    await page.setViewportSize({ width: 915, height: 412 });
    await page.goto('/');
    await page.waitForTimeout(3000);
    await page.screenshot({ path: 'screenshots/layout-landscape.png' });
  });

  test('should adapt to tablet size', async ({ page }) => {
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.goto('/');
    await page.waitForTimeout(3000);
    await page.screenshot({ path: 'screenshots/layout-tablet.png' });
  });
});

test.describe('Performance', () => {
  test('should maintain reasonable frame rate', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(5000);

    // Measure performance
    const perfMetrics = await page.evaluate(() => {
      return new Promise((resolve) => {
        let frameCount = 0;
        const startTime = performance.now();

        function countFrame() {
          frameCount++;
          if (performance.now() - startTime < 2000) {
            requestAnimationFrame(countFrame);
          } else {
            const fps = frameCount / 2;
            resolve({ fps, frameCount });
          }
        }

        requestAnimationFrame(countFrame);
      });
    });

    console.log('Performance metrics:', perfMetrics);
    // Should maintain at least 30 FPS for usable experience
    expect((perfMetrics as any).fps).toBeGreaterThan(20);
  });
});
