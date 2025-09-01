'use client';

import { usePerformanceOptimization, useWebVitals, useImageOptimization } from '@/hooks/usePerformanceOptimization';

/**
 * Client-side performance optimization component
 * Applies various performance optimizations after the page loads
 */
export default function PerformanceOptimizer() {
  // Apply performance optimizations
  usePerformanceOptimization();
  
  // Monitor web vitals
  useWebVitals();
  
  // Optimize images
  useImageOptimization();

  // This component doesn't render anything
  return null;
}