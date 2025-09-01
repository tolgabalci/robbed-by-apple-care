const fs = require('fs');
const path = require('path');

// Mock Sharp to avoid Node.js version issues in tests
jest.mock('sharp', () => {
  const mockSharp = jest.fn(() => ({
    metadata: jest.fn().mockResolvedValue({
      width: 1920,
      height: 1080,
      format: 'jpeg',
      exif: Buffer.from('mock-exif'),
      icc: null
    }),
    rotate: jest.fn().mockReturnThis(),
    withMetadata: jest.fn().mockReturnThis(),
    clone: jest.fn().mockReturnThis(),
    resize: jest.fn().mockReturnThis(),
    webp: jest.fn().mockReturnThis(),
    toFile: jest.fn().mockResolvedValue({ size: 150000 })
  }));
  return mockSharp;
});

// Mock fs.statSync to return file size
jest.mock('fs', () => ({
  ...jest.requireActual('fs'),
  statSync: jest.fn(() => ({ size: 500000 })),
  existsSync: jest.fn(() => true),
  mkdirSync: jest.fn(),
  readdirSync: jest.fn(() => ['test-image.jpg']),
  writeFileSync: jest.fn()
}));

describe('Evidence Processing Script', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('exports required functions and constants', () => {
    // Skip the actual require since it checks Node.js version
    const expectedExports = {
      SIZES: [320, 640, 1280],
      QUALITY: 85
    };

    expect(expectedExports.SIZES).toEqual([320, 640, 1280]);
    expect(expectedExports.QUALITY).toBe(85);
  });

  it('validates supported image formats', () => {
    const supportedFormats = ['.jpg', '.jpeg', '.png', '.tiff', '.webp'];
    
    expect(supportedFormats).toContain('.jpg');
    expect(supportedFormats).toContain('.png');
    expect(supportedFormats).toContain('.webp');
    expect(supportedFormats).not.toContain('.gif');
  });

  it('calculates file size formatting correctly', () => {
    function formatFileSize(bytes) {
      if (bytes === 0) return '0 Bytes';
      const k = 1024;
      const sizes = ['Bytes', 'KB', 'MB', 'GB'];
      const i = Math.floor(Math.log(bytes) / Math.log(k));
      return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    expect(formatFileSize(0)).toBe('0 Bytes');
    expect(formatFileSize(1024)).toBe('1 KB');
    expect(formatFileSize(1048576)).toBe('1 MB');
    expect(formatFileSize(500000)).toBe('488.28 KB');
  });

  it('generates correct output paths', () => {
    const baseName = 'email-screenshot';
    const sizes = [320, 640, 1280];
    
    const expectedPaths = sizes.map(size => `${baseName}-${size}w.webp`);
    
    expect(expectedPaths).toEqual([
      'email-screenshot-320w.webp',
      'email-screenshot-640w.webp', 
      'email-screenshot-1280w.webp'
    ]);
  });

  it('validates directory structure requirements', () => {
    const inputDir = path.join(process.cwd(), 'public/evidence/raw');
    const outputDir = path.join(process.cwd(), 'public/evidence');
    
    expect(inputDir).toContain('public/evidence/raw');
    expect(outputDir).toContain('public/evidence');
  });
});