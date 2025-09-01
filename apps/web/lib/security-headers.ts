/**
 * Security headers configuration and validation utilities
 * Used for testing and ensuring proper security header implementation
 */

export interface SecurityHeaders {
  'Content-Security-Policy': string;
  'Strict-Transport-Security': string;
  'X-Frame-Options': string;
  'X-Content-Type-Options': string;
  'Referrer-Policy': string;
  'Permissions-Policy': string;
  'X-DNS-Prefetch-Control': string;
  'X-XSS-Protection': string;
}

export const EXPECTED_SECURITY_HEADERS: SecurityHeaders = {
  'Content-Security-Policy': [
    "default-src 'self'",
    "img-src 'self' data: https://*.blob.core.windows.net https://www.robbedbyapplecare.com",
    "script-src 'self' 'unsafe-inline' https://forum.robbedbyapplecare.com",
    "style-src 'self' 'unsafe-inline'",
    "connect-src 'self' https://forum.robbedbyapplecare.com",
    "frame-src https://forum.robbedbyapplecare.com",
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    "object-src 'none'",
    "upgrade-insecure-requests"
  ].join('; '),
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',
  'X-Frame-Options': 'DENY',
  'X-Content-Type-Options': 'nosniff',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Permissions-Policy': [
    'camera=()',
    'microphone=()',
    'geolocation=()',
    'payment=()',
    'usb=()',
    'magnetometer=()',
    'gyroscope=()',
    'accelerometer=()',
    'ambient-light-sensor=()',
    'autoplay=()',
    'encrypted-media=()',
    'fullscreen=(self)',
    'picture-in-picture=()'
  ].join(', '),
  'X-DNS-Prefetch-Control': 'on',
  'X-XSS-Protection': '1; mode=block',
};

/**
 * Validates that response headers contain expected security headers
 */
export function validateSecurityHeaders(headers: Record<string, string>): {
  valid: boolean;
  missing: string[];
  incorrect: Array<{ header: string; expected: string; actual: string }>;
} {
  const missing: string[] = [];
  const incorrect: Array<{ header: string; expected: string; actual: string }> = [];

  for (const [headerName, expectedValue] of Object.entries(EXPECTED_SECURITY_HEADERS)) {
    const actualValue = headers[headerName.toLowerCase()] || headers[headerName];
    
    if (!actualValue) {
      missing.push(headerName);
    } else if (actualValue !== expectedValue) {
      incorrect.push({
        header: headerName,
        expected: expectedValue,
        actual: actualValue,
      });
    }
  }

  return {
    valid: missing.length === 0 && incorrect.length === 0,
    missing,
    incorrect,
  };
}

/**
 * Checks if x-powered-by header is properly removed
 */
export function validatePoweredByRemoval(headers: Record<string, string>): boolean {
  return !headers['x-powered-by'] && !headers['X-Powered-By'];
}