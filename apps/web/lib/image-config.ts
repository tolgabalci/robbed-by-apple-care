import fs from 'fs';
import path from 'path';

export interface ImageConfig {
  [key: string]: {
    original: {
      src: string;
      width: number;
      height: number;
      size: number;
    };
    responsive: {
      [size: number]: {
        src: string;
        width: number;
        height: number;
        size: number;
      };
    };
  };
}

let imageConfig: ImageConfig | null = null;

/**
 * Load image configuration from processed images
 */
export function loadImageConfig(): ImageConfig {
  if (imageConfig) {
    return imageConfig;
  }

  const configPath = path.join(process.cwd(), 'public/evidence/image-config.json');
  
  try {
    if (fs.existsSync(configPath)) {
      const configData = fs.readFileSync(configPath, 'utf8');
      imageConfig = JSON.parse(configData);
      return imageConfig!;
    }
  } catch (error) {
    console.warn('Could not load image configuration:', error);
  }

  // Return empty config if file doesn't exist or can't be loaded
  return {};
}

/**
 * Get responsive image sources for a given image
 */
export function getResponsiveImageSources(src: string): {
  srcSet?: string;
  sizes?: string;
  fallback: string;
} {
  const config = loadImageConfig();
  
  // Extract base name from src
  const baseName = src.split('/').pop()?.replace(/\.(webp|jpg|jpeg|png|svg)$/, '');
  
  if (!baseName || !config[baseName]) {
    return { fallback: src };
  }

  const imageData = config[baseName];
  
  // Build srcSet from responsive images
  const srcSet = Object.entries(imageData.responsive)
    .map(([size, info]) => `${info.src} ${size}w`)
    .join(', ');

  // Default sizes attribute for responsive behavior
  const sizes = '(max-width: 640px) 320px, (max-width: 1280px) 640px, 1280px';

  return {
    srcSet,
    sizes,
    fallback: imageData.original.src
  };
}

/**
 * Get optimized image src for a specific size
 */
export function getOptimizedImageSrc(src: string, targetWidth?: number): string {
  const config = loadImageConfig();
  const baseName = src.split('/').pop()?.replace(/\.(webp|jpg|jpeg|png|svg)$/, '');
  
  if (!baseName || !config[baseName]) {
    return src;
  }

  const imageData = config[baseName];
  
  if (!targetWidth) {
    return imageData.original.src;
  }

  // Find the best matching size
  const availableSizes = Object.keys(imageData.responsive).map(Number).sort((a, b) => a - b);
  const bestSize = availableSizes.find(size => size >= targetWidth) || availableSizes[availableSizes.length - 1];
  
  return imageData.responsive[bestSize]?.src || imageData.original.src;
}

/**
 * Get image dimensions for a given src
 */
export function getImageDimensions(src: string): { width: number; height: number } | null {
  const config = loadImageConfig();
  const baseName = src.split('/').pop()?.replace(/\.(webp|jpg|jpeg|png|svg)$/, '');
  
  if (!baseName || !config[baseName]) {
    return null;
  }

  const imageData = config[baseName];
  return {
    width: imageData.original.width,
    height: imageData.original.height
  };
}