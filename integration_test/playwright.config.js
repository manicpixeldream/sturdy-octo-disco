import { defineConfig } from '@playwright/test';

const baseURL = 'http://127.0.0.1:7351';

export default defineConfig({
  testDir: '.',
  testMatch: '*.spec.js',
  timeout: 60000,
  use: {
    baseURL,
    actionTimeout: 10000,
    channel: 'chrome',
    viewport: { width: 1280, height: 1000 },
    locale: 'en-US',
    timezoneId: 'UTC',
    trace: 'retain-on-failure',
  },
  webServer: {
    command: 'python3 -m http.server 7351 --bind 127.0.0.1 --directory ../build/web',
    url: baseURL,
    reuseExistingServer: false,
  },
});
