/**
 * @jest-environment jsdom
 */

import { validateSecurityHeaders, validatePoweredByRemoval, EXPECTED_SECURITY_HEADERS } from '../lib/security-headers';

describe('Security Headers', () => {
  describe('validateSecurityHeaders', () => {
    it('should validate correct security headers', () => {
      const headers = {
        'content-security-policy': EXPECTED_SECURITY_HEADERS['Content-Security-Policy'],
        'strict-transport-security': EXPECTED_SECURITY_HEADERS['Strict-Transport-Security'],
        'x-frame-options': EXPECTED_SECURITY_HEADERS['X-Frame-Options'],
        'x-content-type-options': EXPECTED_SECURITY_HEADERS['X-Content-Type-Options'],
        'referrer-policy': EXPECTED_SECURITY_HEADERS['Referrer-Policy'],
        'permissions-policy': EXPECTED_SECURITY_HEADERS['Permissions-Policy'],
        'x-dns-prefetch-control': EXPECTED_SECURITY_HEADERS['X-DNS-Prefetch-Control'],
        'x-xss-protection': EXPECTED_SECURITY_HEADERS['X-XSS-Protection'],
      };

      const result = validateSecurityHeaders(headers);
      expect(result.valid).toBe(true);
      expect(result.missing).toHaveLength(0);
      expect(result.incorrect).toHaveLength(0);
    });

    it('should detect missing security headers', () => {
      const headers = {
        'content-security-policy': EXPECTED_SECURITY_HEADERS['Content-Security-Policy'],
        // Missing other headers
      };

      const result = validateSecurityHeaders(headers);
      expect(result.valid).toBe(false);
      expect(result.missing).toContain('Strict-Transport-Security');
      expect(result.missing).toContain('X-Frame-Options');
    });

    it('should detect incorrect security header values', () => {
      const headers = {
        'content-security-policy': "default-src 'unsafe-eval'", // Incorrect CSP
        'strict-transport-security': EXPECTED_SECURITY_HEADERS['Strict-Transport-Security'],
        'x-frame-options': EXPECTED_SECURITY_HEADERS['X-Frame-Options'],
        'x-content-type-options': EXPECTED_SECURITY_HEADERS['X-Content-Type-Options'],
        'referrer-policy': EXPECTED_SECURITY_HEADERS['Referrer-Policy'],
        'permissions-policy': EXPECTED_SECURITY_HEADERS['Permissions-Policy'],
        'x-dns-prefetch-control': EXPECTED_SECURITY_HEADERS['X-DNS-Prefetch-Control'],
        'x-xss-protection': EXPECTED_SECURITY_HEADERS['X-XSS-Protection'],
      };

      const result = validateSecurityHeaders(headers);
      expect(result.valid).toBe(false);
      expect(result.incorrect).toHaveLength(1);
      expect(result.incorrect[0].header).toBe('Content-Security-Policy');
    });
  });

  describe('validatePoweredByRemoval', () => {
    it('should pass when x-powered-by header is not present', () => {
      const headers = {
        'content-type': 'text/html',
        'cache-control': 'no-cache',
      };

      expect(validatePoweredByRemoval(headers)).toBe(true);
    });

    it('should fail when x-powered-by header is present (lowercase)', () => {
      const headers = {
        'x-powered-by': 'Next.js',
        'content-type': 'text/html',
      };

      expect(validatePoweredByRemoval(headers)).toBe(false);
    });

    it('should fail when X-Powered-By header is present (uppercase)', () => {
      const headers = {
        'X-Powered-By': 'Next.js',
        'content-type': 'text/html',
      };

      expect(validatePoweredByRemoval(headers)).toBe(false);
    });
  });

  describe('CSP Configuration', () => {
    it('should include all required CSP directives', () => {
      const csp = EXPECTED_SECURITY_HEADERS['Content-Security-Policy'];
      
      expect(csp).toContain("default-src 'self'");
      expect(csp).toContain("frame-ancestors 'none'");
      expect(csp).toContain("object-src 'none'");
      expect(csp).toContain("upgrade-insecure-requests");
      expect(csp).toContain("https://forum.robbedbyapplecare.com");
      expect(csp).toContain("https://*.blob.core.windows.net");
    });

    it('should allow necessary sources for Discourse integration', () => {
      const csp = EXPECTED_SECURITY_HEADERS['Content-Security-Policy'];
      
      expect(csp).toContain("script-src 'self' 'unsafe-inline' https://forum.robbedbyapplecare.com");
      expect(csp).toContain("frame-src https://forum.robbedbyapplecare.com");
      expect(csp).toContain("connect-src 'self' https://forum.robbedbyapplecare.com");
    });
  });

  describe('HSTS Configuration', () => {
    it('should have proper HSTS configuration', () => {
      const hsts = EXPECTED_SECURITY_HEADERS['Strict-Transport-Security'];
      
      expect(hsts).toContain('max-age=31536000');
      expect(hsts).toContain('includeSubDomains');
      expect(hsts).toContain('preload');
    });
  });

  describe('Permissions Policy', () => {
    it('should restrict dangerous permissions', () => {
      const permissionsPolicy = EXPECTED_SECURITY_HEADERS['Permissions-Policy'];
      
      expect(permissionsPolicy).toContain('camera=()');
      expect(permissionsPolicy).toContain('microphone=()');
      expect(permissionsPolicy).toContain('geolocation=()');
      expect(permissionsPolicy).toContain('payment=()');
    });

    it('should allow necessary permissions', () => {
      const permissionsPolicy = EXPECTED_SECURITY_HEADERS['Permissions-Policy'];
      
      expect(permissionsPolicy).toContain('fullscreen=(self)');
    });
  });
});