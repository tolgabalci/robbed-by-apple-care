import { useState } from 'react';

interface ResponsiveImageProps {
  src: string;
  alt: string;
  className?: string;
  sizes?: string;
  loading?: 'lazy' | 'eager';
  onClick?: () => void;
}

interface ResponsiveImageConfig {
  original: {
    src: string;
    width: number;
    height: number;
  };
  responsive?: {
    [key: number]: {
      src: string;
      width: number;
      height: number;
    };
  };
}

/**
 * Get responsive image configuration from processed images
 * This would typically come from the image-config.json file
 */
function getResponsiveConfig(src: string): ResponsiveImageConfig | null {
  // Extract base name from src (e.g., "/evidence/email-1.webp" -> "email-1")
  const baseName = src.split('/').pop()?.replace('.webp', '').replace('.svg', '').replace('.jpg', '').replace('.png', '');
  
  // For now, return null for non-processed images (like our SVG placeholders)
  // In a real implementation, this would load from image-config.json
  if (!baseName || src.includes('.svg')) {
    return null;
  }
  
  // Mock responsive configuration for demonstration
  return {
    original: {
      src: `/evidence/${baseName}.webp`,
      width: 1920,
      height: 1080
    },
    responsive: {
      320: {
        src: `/evidence/${baseName}-320w.webp`,
        width: 320,
        height: 180
      },
      640: {
        src: `/evidence/${baseName}-640w.webp`,
        width: 640,
        height: 360
      },
      1280: {
        src: `/evidence/${baseName}-1280w.webp`,
        width: 1280,
        height: 720
      }
    }
  };
}

export default function ResponsiveImage({
  src,
  alt,
  className = '',
  sizes = '(max-width: 640px) 320px, (max-width: 1280px) 640px, 1280px',
  loading = 'lazy',
  onClick
}: ResponsiveImageProps) {
  const [imageError, setImageError] = useState(false);
  const config = getResponsiveConfig(src);

  // Handle image load error
  const handleError = () => {
    setImageError(true);
  };

  // If no responsive config or error, use original image
  if (!config || imageError) {
    return (
      <img
        src={src}
        alt={alt}
        className={className}
        loading={loading}
        onClick={onClick}
        onError={handleError}
      />
    );
  }

  // Build srcSet from responsive configuration
  const srcSet = config.responsive
    ? Object.entries(config.responsive)
        .map(([size, info]) => `${info.src} ${size}w`)
        .join(', ')
    : undefined;

  return (
    <picture>
      {/* WebP sources with responsive sizes */}
      {srcSet && (
        <source
          srcSet={srcSet}
          sizes={sizes}
          type="image/webp"
        />
      )}
      
      {/* Fallback image */}
      <img
        src={config.original.src}
        alt={alt}
        className={className}
        loading={loading}
        onClick={onClick}
        onError={handleError}
        width={config.original.width}
        height={config.original.height}
      />
    </picture>
  );
}