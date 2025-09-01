'use client';

import { useEffect, useRef, useState, useCallback } from 'react';

interface DiscourseEmbedProps {
  discourseUrl: string;
  className?: string;
}

interface DiscourseEmbedConfig {
  discourseUrl: string;
  discourseEmbedUrl: string;
  discourseUserName?: string;
  topicId?: number;
}

declare global {
  interface Window {
    DiscourseEmbed?: DiscourseEmbedConfig;
  }
}

export default function DiscourseEmbed({ 
  discourseUrl, 
  className = '' 
}: DiscourseEmbedProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);
  const [retryCount, setRetryCount] = useState(0);
  const maxRetries = 3;

  // Get canonical URL for topic creation
  const getCanonicalUrl = (): string => {
    // First try to get canonical URL from link tag
    const canonicalLink = document.querySelector('link[rel="canonical"]') as HTMLLinkElement;
    if (canonicalLink?.href) {
      return canonicalLink.href;
    }
    
    // Fallback to current URL without hash/query params
    const url = new URL(window.location.href);
    url.hash = '';
    url.search = '';
    return url.toString();
  };

  const loadDiscourseEmbed = useCallback(async () => {
    try {
      setIsLoading(true);
      setHasError(false);

      // Clean up any existing embed
      if (containerRef.current) {
        containerRef.current.innerHTML = '';
      }

      // Remove any existing Discourse embed script
      const existingScript = document.querySelector('script[src*="embed.js"]');
      if (existingScript) {
        existingScript.remove();
      }

      // Configure Discourse embed
      const embedUrl = getCanonicalUrl();
      window.DiscourseEmbed = {
        discourseUrl: discourseUrl.replace(/\/$/, ''), // Remove trailing slash
        discourseEmbedUrl: embedUrl,
        discourseUserName: 'system', // User for auto-topic creation
      };

      // Create and load the embed script
      const script = document.createElement('script');
      script.type = 'text/javascript';
      script.async = true;
      script.src = `${discourseUrl.replace(/\/$/, '')}/javascripts/embed.js`;
      
      // Handle script load success
      script.onload = () => {
        setIsLoading(false);
        setHasError(false);
        setRetryCount(0);
      };

      // Handle script load error
      script.onerror = () => {
        console.error('Failed to load Discourse embed script');
        setIsLoading(false);
        setHasError(true);
      };

      // Add script to document
      document.head.appendChild(script);

      // Set a timeout to detect if embed doesn't load
      setTimeout(() => {
        if (isLoading) {
          console.warn('Discourse embed taking longer than expected to load');
          setIsLoading(false);
          setHasError(true);
        }
      }, 10000); // 10 second timeout

    } catch (error) {
      console.error('Error loading Discourse embed:', error);
      setIsLoading(false);
      setHasError(true);
    }
  }, [discourseUrl, isLoading]);

  const handleRetry = () => {
    if (retryCount < maxRetries) {
      setRetryCount(prev => prev + 1);
      // Exponential backoff: 1s, 2s, 4s
      const delay = Math.pow(2, retryCount) * 1000;
      setTimeout(() => {
        loadDiscourseEmbed();
      }, delay);
    }
  };

  useEffect(() => {
    // Only load on client side
    if (typeof window !== 'undefined') {
      loadDiscourseEmbed();
    }

    // Cleanup function
    return () => {
      // Clean up global config
      if (window.DiscourseEmbed) {
        delete window.DiscourseEmbed;
      }
      
      // Remove embed script
      const script = document.querySelector('script[src*="embed.js"]');
      if (script) {
        script.remove();
      }
    };
  }, [discourseUrl, loadDiscourseEmbed]);

  return (
    <section 
      id="comments" 
      className={`scroll-mt-20 ${className}`}
      aria-label="Comments section"
    >
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-2">
          <a href="#comments" className="hover:underline">
            Discussion
          </a>
        </h2>
        <p className="text-gray-600 dark:text-gray-400 text-sm">
          Share your experiences and join the conversation below. 
          You can log in with Google or Facebook to participate.
        </p>
      </div>

      {/* Loading State */}
      {isLoading && !hasError && (
        <div className="flex items-center justify-center py-12">
          <div className="flex items-center space-x-3">
            <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
            <span className="text-gray-600 dark:text-gray-400">
              Loading comments...
            </span>
          </div>
        </div>
      )}

      {/* Error State */}
      {hasError && (
        <div className="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-6">
          <div className="flex items-start space-x-3">
            <div className="flex-shrink-0">
              <svg 
                className="h-5 w-5 text-yellow-600 dark:text-yellow-400" 
                fill="currentColor" 
                viewBox="0 0 20 20"
                aria-hidden="true"
              >
                <path 
                  fillRule="evenodd" 
                  d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" 
                  clipRule="evenodd" 
                />
              </svg>
            </div>
            <div className="flex-1">
              <h3 className="text-sm font-medium text-yellow-800 dark:text-yellow-200">
                Comments temporarily unavailable
              </h3>
              <p className="mt-1 text-sm text-yellow-700 dark:text-yellow-300">
                We&apos;re having trouble loading the discussion forum. This might be due to a 
                temporary network issue or the forum being under maintenance.
              </p>
              <div className="mt-4 flex flex-col sm:flex-row gap-3">
                {retryCount < maxRetries && (
                  <button
                    onClick={handleRetry}
                    className="inline-flex items-center px-3 py-2 border border-yellow-300 dark:border-yellow-600 shadow-sm text-sm leading-4 font-medium rounded-md text-yellow-800 dark:text-yellow-200 bg-yellow-100 dark:bg-yellow-800/30 hover:bg-yellow-200 dark:hover:bg-yellow-800/50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 transition-colors"
                    disabled={isLoading}
                  >
                    {isLoading ? (
                      <>
                        <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-yellow-600 mr-2"></div>
                        Retrying...
                      </>
                    ) : (
                      <>
                        <svg className="h-4 w-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                        </svg>
                        Try Again ({maxRetries - retryCount} attempts left)
                      </>
                    )}
                  </button>
                )}
                <a
                  href={`${discourseUrl.replace(/\/$/, '')}/`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-blue-700 dark:text-blue-300 bg-blue-100 dark:bg-blue-900/30 hover:bg-blue-200 dark:hover:bg-blue-900/50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors"
                >
                  <svg className="h-4 w-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                  </svg>
                  Continue discussion on forum
                </a>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Discourse Embed Container */}
      <div 
        ref={containerRef}
        id="discourse-comments"
        className={`${isLoading || hasError ? 'hidden' : ''}`}
        style={{ minHeight: '200px' }}
      />

      {/* Prefetch Discourse assets when component mounts */}
      {typeof window !== 'undefined' && (
        <>
          <link 
            rel="dns-prefetch" 
            href={new URL(discourseUrl).hostname} 
          />
          <link 
            rel="preconnect" 
            href={discourseUrl.replace(/\/$/, '')} 
            crossOrigin="anonymous"
          />
        </>
      )}
    </section>
  );
}