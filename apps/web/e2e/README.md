# End-to-End Testing with Playwright

This directory contains comprehensive end-to-end tests for the RobbedByAppleCare web application using Playwright.

## Setup

### First Time Setup

1. Install Playwright browsers:
   ```bash
   npm run test:e2e:setup
   # or
   npx playwright install
   ```

2. Make sure the development server is running:
   ```bash
   npm run dev
   ```

## Running Tests

### All E2E Tests
```bash
npm run test:e2e
```

### Interactive Mode (UI)
```bash
npm run test:e2e:ui
```

### Headed Mode (See Browser)
```bash
npm run test:e2e:headed
```

### Specific Test Files
```bash
npx playwright test e2e/accessibility.spec.ts
npx playwright test e2e/performance.spec.ts
npx playwright test e2e/responsive-design.spec.ts
npx playwright test e2e/article-reading.spec.ts
```

### Run Tests on Specific Browsers
```bash
npx playwright test --project=chromium
npx playwright test --project=firefox
npx playwright test --project=webkit
npx playwright test --project="Mobile Chrome"
npx playwright test --project="Mobile Safari"
```

## Test Categories

### 1. Article Reading Experience (`article-reading.spec.ts`)
Tests the core user journey of reading the article:
- Article title and content display
- Navigation structure
- Evidence gallery functionality
- Timeline section
- Discourse comments integration
- Semantic HTML structure
- Social sharing features

### 2. Accessibility (`accessibility.spec.ts`)
Comprehensive accessibility testing:
- Heading hierarchy validation
- Alt text for images
- Link accessibility
- Form and button accessibility
- ARIA landmarks and attributes
- Keyboard navigation support
- Focus management
- Screen reader compatibility
- Color contrast validation
- Semantic structure

### 3. Performance (`performance.spec.ts`)
Performance metrics and optimization validation:
- Core Web Vitals (LCP, FID, CLS, FCP, TTI)
- Image loading efficiency
- Resource loading optimization
- Time to First Byte (TTFB)
- Network condition handling
- JavaScript bundle efficiency
- Above-the-fold content rendering
- Concurrent user simulation

### 4. Responsive Design (`responsive-design.spec.ts`)
Multi-device and viewport testing:
- Desktop layout (1280x720)
- Tablet layout (768x1024)
- Mobile layout (375x667)
- Large desktop (1920x1080)
- Orientation changes
- Zoom level handling (150%, 200%)
- Evidence gallery responsiveness
- Navigation adaptation

### 5. Setup Verification (`setup-verification.spec.ts`)
Basic Playwright configuration validation:
- Browser configuration
- Viewport settings
- Mobile/desktop support

## Configuration

The tests are configured in `playwright.config.ts` with:
- **Base URL**: `http://localhost:3000`
- **Browsers**: Chromium, Firefox, WebKit
- **Mobile Devices**: Pixel 5, iPhone 12
- **Retries**: 2 on CI, 0 locally
- **Parallel Execution**: Enabled
- **Trace Collection**: On first retry

## Test Data and Mocking

Tests use:
- Mock data for consistent testing
- Network interception for performance tests
- Viewport manipulation for responsive tests
- Keyboard and mouse simulation for accessibility

## Debugging

### View Test Results
```bash
npx playwright show-report
```

### Debug Specific Test
```bash
npx playwright test --debug e2e/accessibility.spec.ts
```

### Generate Test Code
```bash
npx playwright codegen localhost:3000
```

## CI/CD Integration

Tests are designed to run in CI environments with:
- Headless execution
- Retry logic for flaky tests
- HTML report generation
- Screenshot and video capture on failures

## Requirements

- **Node.js**: 18+ (for Playwright compatibility)
- **Development Server**: Must be running on localhost:3000
- **Browser Binaries**: Installed via `playwright install`

## Troubleshooting

### Common Issues

1. **Browser not found**: Run `npm run test:e2e:setup`
2. **Connection refused**: Ensure dev server is running (`npm run dev`)
3. **Timeout errors**: Check if localhost:3000 is accessible
4. **Flaky tests**: Use `--retries=3` flag for unstable networks

### Performance Test Considerations

Performance tests may fail on:
- Slow machines or networks
- High system load
- Development vs production builds
- Different hardware configurations

Adjust thresholds in `performance.spec.ts` if needed for your environment.

## Best Practices

1. **Keep tests independent**: Each test should work in isolation
2. **Use proper selectors**: Prefer `data-testid` over CSS selectors
3. **Handle async operations**: Use `waitFor` for dynamic content
4. **Mock external services**: Avoid dependencies on external APIs
5. **Test real user scenarios**: Focus on actual user workflows