'use client';

import { useState, useRef, useEffect } from 'react';

interface LazyImageProps {
  src: string;
  alt: string;
  className?: string;
  sizes?: string;
  onClick?: () => void;
  placeholder?: string;
  blurDataURL?: string;
  priority?: boolean;
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
 */
function getResponsiveConfig(src: string): ResponsiveImageConfig | null {
  const baseName = src.split('/').pop()?.replace(/\.(webp|svg|jpg|png)$/, '');
  
  if (!baseName || src.includes('.svg')) {
    return null;
  }
  
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

export default function LazyImage({
  src,
  alt,
  className = '',
  sizes = '(max-width: 640px) 320px, (max-width: 1280px) 640px, 1280px',
  onClick,
  placeholder = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0iI2Y3ZjhmOSIvPjx0ZXh0IHg9IjUwIiB5PSI1MCIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjE0IiBmaWxsPSIjOWNhM2FmIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBkeT0iLjNlbSI+TG9hZGluZy4uLjwvdGV4dD48L3N2Zz4=',
  blurDataURL,
  priority = false
}: LazyImageProps) {
  const [isLoaded, setIsLoaded] = useState(false);
  const [isInView, setIsInView] = useState(priority);
  const [imageError, setImageError] = useState(false);
  const imgRef = useRef<HTMLImageElement>(null);
  const config = getResponsiveConfig(src);

  // Intersection Observer for lazy loading
  useEffect(() => {
    if (priority || isInView) return;

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setIsInView(true);
            observer.disconnect();
          }
        });
      },
      {
        rootMargin: '50px', // Start loading 50px before the image comes into view
        threshold: 0.1,
      }
    );

    if (imgRef.current) {
      observer.observe(imgRef.current);
    }

    return () => observer.disconnect();
  }, [priority, isInView]);

  const handleLoad = () => {
    setIsLoaded(true);
  };

  const handleError = () => {
    setImageError(true);
    setIsLoaded(true); // Consider error state as "loaded" to remove placeholder
  };

  // Build srcSet from responsive configuration
  const srcSet = config?.responsive
    ? Object.entries(config.responsive)
        .map(([size, info]) => `${info.src} ${size}w`)
        .join(', ')
    : undefined;

  const imageSrc = config?.original.src || src;

  return (
    <div className={`relative overflow-hidden ${className}`} ref={imgRef}>
      {/* Placeholder/blur background */}
      {!isLoaded && (
        <div 
          className="absolute inset-0 bg-gray-200 animate-pulse flex items-center justify-center"
          style={{
            backgroundImage: blurDataURL ? `url(${blurDataURL})` : `url(${placeholder})`,
            backgroundSize: 'cover',
            backgroundPosition: 'center',
            filter: blurDataURL ? 'blur(10px)' : 'none',
          }}
        >
          {!blurDataURL && (
            <div className="text-gray-400 text-sm">Loading...</div>
          )}
        </div>
      )}

      {/* Actual image - render when in view, priority, or for testing */}
      {(isInView || priority || process.env.NODE_ENV === 'test') && (
        config?.responsive ? (
          <picture>
            {/* WebP sources with responsive sizes */}
            {srcSet && !imageError && (
              <source
                srcSet={srcSet}
                sizes={sizes}
                type="image/webp"
              />
            )}
            
            {/* Fallback image */}
            <img
              src={imageSrc}
              alt={alt}
              className={`w-full h-full object-cover transition-opacity duration-300 ${
                isLoaded ? 'opacity-100' : 'opacity-0'
              }`}
              loading={priority ? 'eager' : 'lazy'}
              onClick={onClick}
              onLoad={handleLoad}
              onError={handleError}
              width={config?.original.width}
              height={config?.original.height}
              decoding="async"
            />
          </picture>
        ) : (
          <img
            src={imageSrc}
            alt={alt}
            className={`w-full h-full object-cover transition-opacity duration-300 ${
              isLoaded ? 'opacity-100' : 'opacity-0'
            }`}
            loading={priority ? 'eager' : 'lazy'}
            onClick={onClick}
            onLoad={handleLoad}
            onError={handleError}
            decoding="async"
          />
        )
      )}
    </div>
  );
}