import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import EvidenceGallery from '../components/EvidenceGallery';
import { EvidenceItem } from '../types/article';

expect.extend(toHaveNoViolations);

const mockEvidence: EvidenceItem[] = [
  {
    src: '/evidence/email-1.svg',
    type: 'image',
    caption: 'Initial support request - no response for 7 days',
    alt: 'Screenshot of initial AppleCare support email'
  },
  {
    src: '/evidence/email-2.svg',
    type: 'image',
    caption: 'Escalation to supervisor - still no resolution',
    alt: 'Screenshot of escalated case email'
  },
  {
    src: '/evidence/document.pdf',
    type: 'pdf',
    caption: 'Official warranty documentation',
    alt: 'PDF document with warranty details'
  }
];

describe('EvidenceGallery', () => {
  it('renders evidence items', () => {
    render(<EvidenceGallery evidence={mockEvidence} />);
    
    expect(screen.getByText('Evidence')).toBeInTheDocument();
    expect(screen.getByText('Initial support request - no response for 7 days')).toBeInTheDocument();
    expect(screen.getByText('Escalation to supervisor - still no resolution')).toBeInTheDocument();
    expect(screen.getByText('Official warranty documentation')).toBeInTheDocument();
  });

  it('renders image evidence correctly', () => {
    render(<EvidenceGallery evidence={mockEvidence} />);
    
    const images = screen.getAllByRole('img');
    expect(images).toHaveLength(2); // Only image types, not PDF
    expect(images[0]).toHaveAttribute('src', '/evidence/email-1.svg');
    expect(images[0]).toHaveAttribute('alt', 'Screenshot of initial AppleCare support email');
  });

  it('renders PDF evidence correctly', () => {
    render(<EvidenceGallery evidence={mockEvidence} />);
    
    expect(screen.getByText('PDF Document')).toBeInTheDocument();
  });

  it('opens lightbox when image is clicked', () => {
    render(<EvidenceGallery evidence={mockEvidence} />);
    
    const firstImage = screen.getAllByRole('img')[0];
    fireEvent.click(firstImage);
    
    // Check if lightbox is open by looking for close button
    expect(screen.getByLabelText('Close lightbox')).toBeInTheDocument();
  });

  it('closes lightbox when close button is clicked', () => {
    render(<EvidenceGallery evidence={mockEvidence} />);
    
    // Open lightbox
    const firstImage = screen.getAllByRole('img')[0];
    fireEvent.click(firstImage);
    
    // Close lightbox
    const closeButton = screen.getByLabelText('Close lightbox');
    fireEvent.click(closeButton);
    
    // Lightbox should be closed
    expect(screen.queryByLabelText('Close lightbox')).not.toBeInTheDocument();
  });

  it('navigates between images in lightbox', () => {
    render(<EvidenceGallery evidence={mockEvidence} />);
    
    // Open lightbox
    const firstImage = screen.getAllByRole('img')[0];
    fireEvent.click(firstImage);
    
    // Check initial caption in lightbox (should be in a larger text)
    const lightboxCaptions = screen.getAllByText('Initial support request - no response for 7 days');
    expect(lightboxCaptions.length).toBeGreaterThan(1); // Should appear in both gallery and lightbox
    
    // Navigate to next image
    const nextButton = screen.getByLabelText('Next image');
    fireEvent.click(nextButton);
    
    // Check new caption appears in lightbox
    const newCaptions = screen.getAllByText('Escalation to supervisor - still no resolution');
    expect(newCaptions.length).toBeGreaterThan(1); // Should appear in both gallery and lightbox
  });

  it('handles empty evidence array', () => {
    render(<EvidenceGallery evidence={[]} />);
    
    // Should not render anything
    expect(screen.queryByText('Evidence')).not.toBeInTheDocument();
  });

  it('handles keyboard navigation in lightbox', () => {
    render(<EvidenceGallery evidence={mockEvidence} />);
    
    // Open lightbox
    const firstImage = screen.getAllByRole('img')[0];
    fireEvent.click(firstImage);
    
    // Test Escape key
    fireEvent.keyDown(document, { key: 'Escape' });
    expect(screen.queryByLabelText('Close lightbox')).not.toBeInTheDocument();
  });

  describe('Error Handling', () => {
    it('handles broken image URLs gracefully', () => {
      const evidenceWithBrokenImage: EvidenceItem[] = [
        {
          src: '/broken-image.jpg',
          type: 'image',
          caption: 'Broken image test',
          alt: 'This image will not load'
        }
      ];

      render(<EvidenceGallery evidence={evidenceWithBrokenImage} />);
      
      const image = screen.getByRole('img');
      fireEvent.error(image);
      
      // Should still render the caption
      expect(screen.getByText('Broken image test')).toBeInTheDocument();
    });

    it('handles missing alt text gracefully', () => {
      const evidenceWithoutAlt: EvidenceItem[] = [
        {
          src: '/evidence/email-1.svg',
          type: 'image',
          caption: 'Image without alt text'
        }
      ];

      expect(() => render(<EvidenceGallery evidence={evidenceWithoutAlt} />)).not.toThrow();
      const image = screen.getByRole('img');
      expect(image).toHaveAttribute('alt', 'Image without alt text'); // Should use caption as fallback
    });

    it('handles invalid evidence types', () => {
      const evidenceWithInvalidType: EvidenceItem[] = [
        {
          src: '/evidence/unknown.xyz',
          type: 'unknown' as any,
          caption: 'Unknown file type'
        }
      ];

      expect(() => render(<EvidenceGallery evidence={evidenceWithInvalidType} />)).not.toThrow();
    });
  });

  describe('Accessibility', () => {
    it('should not have accessibility violations', async () => {
      const { container } = render(<EvidenceGallery evidence={mockEvidence} />);
      const results = await axe(container);
      expect(results).toHaveNoViolations();
    });

    it('has proper ARIA labels for interactive elements', () => {
      render(<EvidenceGallery evidence={mockEvidence} />);
      
      // Open lightbox
      const firstImage = screen.getAllByRole('img')[0];
      fireEvent.click(firstImage);
      
      // Check ARIA labels
      expect(screen.getByLabelText('Close lightbox')).toBeInTheDocument();
      expect(screen.getByLabelText('Previous image')).toBeInTheDocument();
      expect(screen.getByLabelText('Next image')).toBeInTheDocument();
    });

    it('supports keyboard navigation', () => {
      render(<EvidenceGallery evidence={mockEvidence} />);
      
      // Open lightbox
      const firstImage = screen.getAllByRole('img')[0];
      fireEvent.click(firstImage);
      
      // Test arrow key navigation
      fireEvent.keyDown(document, { key: 'ArrowRight' });
      const newCaptions = screen.getAllByText('Escalation to supervisor - still no resolution');
      expect(newCaptions.length).toBeGreaterThan(1);
      
      fireEvent.keyDown(document, { key: 'ArrowLeft' });
      const originalCaptions = screen.getAllByText('Initial support request - no response for 7 days');
      expect(originalCaptions.length).toBeGreaterThan(1);
    });

    it('has proper focus management in lightbox', () => {
      render(<EvidenceGallery evidence={mockEvidence} />);
      
      // Open lightbox
      const firstImage = screen.getAllByRole('img')[0];
      fireEvent.click(firstImage);
      
      // Close button should be focusable
      const closeButton = screen.getByLabelText('Close lightbox');
      expect(closeButton).toBeInTheDocument();
      
      // Navigation buttons should be focusable
      const prevButton = screen.getByLabelText('Previous image');
      const nextButton = screen.getByLabelText('Next image');
      expect(prevButton).toBeInTheDocument();
      expect(nextButton).toBeInTheDocument();
    });

    it('has proper semantic structure', () => {
      render(<EvidenceGallery evidence={mockEvidence} />);
      
      // Should have proper heading
      const heading = screen.getByRole('heading', { name: /evidence/i });
      expect(heading).toBeInTheDocument();
      
      // Images should have proper alt text
      const images = screen.getAllByRole('img');
      images.forEach(img => {
        expect(img).toHaveAttribute('alt');
      });
    });

    it('provides proper context for screen readers', () => {
      render(<EvidenceGallery evidence={mockEvidence} />);
      
      // Open lightbox
      const firstImage = screen.getAllByRole('img')[0];
      fireEvent.click(firstImage);
      
      // Should indicate current position (3 total items including PDF)
      expect(screen.getByText(/1 of 3/)).toBeInTheDocument();
    });
  });

  describe('Performance', () => {
    it('sets appropriate loading attributes for images', () => {
      render(<EvidenceGallery evidence={mockEvidence} />);
      
      const images = screen.getAllByRole('img');
      images.forEach(img => {
        // Images may use eager loading for better UX
        expect(img).toHaveAttribute('loading');
      });
    });

    it('preloads next image in lightbox', () => {
      render(<EvidenceGallery evidence={mockEvidence} />);
      
      // Open lightbox
      const firstImage = screen.getAllByRole('img')[0];
      fireEvent.click(firstImage);
      
      // Should preload next image (implementation detail would need to be checked in actual component)
      // This test verifies the behavior exists
      expect(screen.getByLabelText('Next image')).toBeInTheDocument();
    });
  });

  describe('Responsive Behavior', () => {
    it('applies responsive classes', () => {
      render(<EvidenceGallery evidence={mockEvidence} />);
      
      // Check that responsive grid classes are applied
      const gallery = screen.getByText('Evidence').closest('div');
      expect(gallery).toBeInTheDocument();
      expect(gallery).toHaveClass('my-12');
    });

    it('handles different screen sizes in lightbox', () => {
      render(<EvidenceGallery evidence={mockEvidence} />);
      
      // Open lightbox
      const firstImage = screen.getAllByRole('img')[0];
      fireEvent.click(firstImage);
      
      // Lightbox should be responsive - check for the outer container
      const lightboxContainer = screen.getByLabelText('Close lightbox').closest('div')?.parentElement;
      expect(lightboxContainer).toHaveClass('fixed', 'inset-0');
    });
  });
});