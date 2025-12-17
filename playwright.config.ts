/**
 * Playwright Configuration for Synth-VIB3+ Web Testing
 *
 * Tests the deployed web version at domusgpt.github.io/synth-vib3-plus
 * and local development builds.
 */

import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html', { outputFolder: 'playwright-report' }],
    ['json', { outputFile: 'test-results.json' }],
    ['list']
  ],

  use: {
    // Base URL for GitHub Pages deployment
    baseURL: process.env.TEST_URL || 'https://domusgpt.github.io/synth-vib3-plus/',

    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',

    // Viewport for mobile-first testing (Flutter web targets mobile)
    viewport: { width: 412, height: 915 },
  },

  projects: [
    {
      name: 'Mobile Chrome',
      use: {
        ...devices['Pixel 5'],
        // Enable GPU for WebGL
        launchOptions: {
          args: ['--enable-webgl', '--use-gl=angle']
        }
      },
    },
    {
      name: 'Desktop Chrome',
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1280, height: 720 },
        launchOptions: {
          args: ['--enable-webgl', '--use-gl=angle']
        }
      },
    },
  ],

  // Timeout for each test
  timeout: 60000,
  expect: {
    timeout: 10000
  },
});
