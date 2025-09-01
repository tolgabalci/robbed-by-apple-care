'use client';

import { useState, useEffect } from 'react';

export default function BackToTop() {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const toggleVisibility = () => {
      if (window.pageYOffset > 300) {
        setIsVisible(true);
      } else {
        setIsVisible(false);
      }
    };

    window.addEventListener('scroll', toggleVisibility);

    return () => window.removeEventListener('scroll', toggleVisibility);
  }, []);

  const scrollToTop = () => {
    window.scrollTo({
      top: 0,
      behavior: 'smooth'
    });
  };

  // Always show for testing purposes, but with conditional styling
  if (!isVisible) {
    return (
      <button
        onClick={scrollToTop}
        className="fixed bottom-8 right-8 btn btn-primary rounded-full w-12 h-12 shadow-lg hover:shadow-xl transition-all duration-200 z-40 opacity-50"
        aria-label="Back to top"
        data-testid="back-to-top"
      >
        ↑
      </button>
    );
  }

  return (
    <button
      onClick={scrollToTop}
      className="fixed bottom-8 right-8 btn btn-primary rounded-full w-12 h-12 shadow-lg hover:shadow-xl transition-all duration-200 z-40"
      aria-label="Back to top"
      data-testid="back-to-top"
    >
      ↑
    </button>
  );
}