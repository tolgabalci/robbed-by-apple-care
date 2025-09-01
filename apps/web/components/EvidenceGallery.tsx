'use client';

import { useState, useEffect } from 'react';
import { EvidenceItem } from '@/types/article';
import LazyImage from './LazyImage';

interface EvidenceGalleryProps {
  evidence: EvidenceItem[];
}

interface LightboxProps {
  isOpen: boolean;
  currentIndex: number;
  evidence: EvidenceItem[];
  onClose: () => void;
  onNext: () => void;
  onPrevious: () => void;
}

function Lightbox({ isOpen, currentIndex, evidence, onClose, onNext, onPrevious }: LightboxProps) {
  // Handle keyboard navigation
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (event: KeyboardEvent) => {
      switch (event.key) {
        case 'Escape':
          onClose();
          break;
        case 'ArrowLeft':
          onPrevious();
          break;
        case 'ArrowRight':
          onNext();
          break;
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    document.body.style.overflow = 'hidden'; // Prevent background scrolling

    return () => {
      document.removeEventListener('keydown', handleKeyDown);
      document.body.style.overflow = 'unset';
    };
  }, [isOpen, onClose, onNext, onPrevious]);

  if (!isOpen || !evidence[currentIndex]) return null;

  const currentItem = evidence[currentIndex];
  const isImage = currentItem.type === 'image';
  const isPDF = currentItem.type === 'pdf';

  return (
    <div 
      className="fixed inset-0 z-50 bg-black bg-opacity-90 flex items-center justify-center p-4"
      onClick={onClose}
    >
      <div className="relative max-w-7xl max-h-full w-full h-full flex flex-col">
        {/* Close button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 z-10 text-white hover:text-gray-300 transition-colors"
          aria-label="Close lightbox"
        >
          <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>

        {/* Navigation buttons */}
        {evidence.length > 1 && (
          <>
            <button
              onClick={(e) => {
                e.stopPropagation();
                onPrevious();
              }}
              className="absolute left-4 top-1/2 transform -translate-y-1/2 z-10 text-white hover:text-gray-300 transition-colors"
              aria-label="Previous image"
            >
              <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
            </button>
            <button
              onClick={(e) => {
                e.stopPropagation();
                onNext();
              }}
              className="absolute right-4 top-1/2 transform -translate-y-1/2 z-10 text-white hover:text-gray-300 transition-colors"
              aria-label="Next image"
            >
              <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </button>
          </>
        )}

        {/* Content area */}
        <div 
          className="flex-1 flex items-center justify-center"
          onClick={(e) => e.stopPropagation()}
        >
          {isImage && (
            <img
              src={currentItem.src}
              alt={currentItem.alt || currentItem.caption}
              className="max-w-full max-h-full object-contain"
              loading="lazy"
            />
          )}
          {isPDF && (
            <div className="bg-white rounded-lg p-8 max-w-md text-center">
              <svg className="w-16 h-16 mx-auto mb-4 text-red-600" fill="currentColor" viewBox="0 0 24 24">
                <path d="M14,2H6A2,2 0 0,0 4,4V20A2,2 0 0,0 6,22H18A2,2 0 0,0 20,20V8L14,2M18,20H6V4H13V9H18V20Z" />
              </svg>
              <h3 className="text-lg font-semibold mb-2">PDF Document</h3>
              <p className="text-gray-600 mb-4">{currentItem.caption}</p>
              <a
                href={currentItem.src}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                Open PDF
              </a>
            </div>
          )}
        </div>

        {/* Caption and counter */}
        <div className="text-center text-white p-4">
          <p className="text-lg mb-2">{currentItem.caption}</p>
          {evidence.length > 1 && (
            <p className="text-sm text-gray-300">
              {currentIndex + 1} of {evidence.length}
            </p>
          )}
        </div>
      </div>
    </div>
  );
}

export default function EvidenceGallery({ evidence }: EvidenceGalleryProps) {
  const [lightboxOpen, setLightboxOpen] = useState(false);
  const [currentIndex, setCurrentIndex] = useState(0);

  const openLightbox = (index: number) => {
    setCurrentIndex(index);
    setLightboxOpen(true);
  };

  const closeLightbox = () => {
    setLightboxOpen(false);
  };

  const nextImage = () => {
    setCurrentIndex((prev) => (prev + 1) % evidence.length);
  };

  const previousImage = () => {
    setCurrentIndex((prev) => (prev - 1 + evidence.length) % evidence.length);
  };

  if (!evidence || evidence.length === 0) {
    return null;
  }

  return (
    <div className="my-12" data-testid="evidence-gallery">
      <h2 className="text-2xl font-bold mb-6 text-gray-900">Evidence</h2>
      
      {/* Gallery Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {evidence.map((item, index) => (
          <div
            key={index}
            className="group cursor-pointer bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow duration-200"
            onClick={() => openLightbox(index)}
          >
            <div className="relative aspect-video bg-gray-100 flex items-center justify-center">
              {item.type === 'image' ? (
                <>
                  <LazyImage
                    src={item.src}
                    alt={item.alt || item.caption}
                    className="w-full h-full group-hover:scale-105 transition-transform duration-200"
                    priority={index < 3} // Prioritize first 3 images
                  />
                  {/* Overlay on hover */}
                  <div className="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-20 transition-all duration-200 flex items-center justify-center">
                    <svg className="w-8 h-8 text-white opacity-0 group-hover:opacity-100 transition-opacity duration-200" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7" />
                    </svg>
                  </div>
                </>
              ) : (
                <div className="flex flex-col items-center justify-center p-6 text-center group-hover:bg-gray-50 transition-colors duration-200">
                  <svg className="w-12 h-12 text-red-600 mb-2" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M14,2H6A2,2 0 0,0 4,4V20A2,2 0 0,0 6,22H18A2,2 0 0,0 20,20V8L14,2M18,20H6V4H13V9H18V20Z" />
                  </svg>
                  <span className="text-sm font-medium text-gray-700">PDF Document</span>
                </div>
              )}
            </div>
            
            {/* Caption */}
            <div className="p-4">
              <p className="text-sm text-gray-600 overflow-hidden" style={{
                display: '-webkit-box',
                WebkitLineClamp: 2,
                WebkitBoxOrient: 'vertical'
              }}>{item.caption}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Lightbox */}
      <Lightbox
        isOpen={lightboxOpen}
        currentIndex={currentIndex}
        evidence={evidence}
        onClose={closeLightbox}
        onNext={nextImage}
        onPrevious={previousImage}
      />
    </div>
  );
}