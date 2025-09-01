# Image Processing Workflow

This document explains the complete image processing workflow for evidence images in the RobbedByAppleCare project.

## Overview

The image processing system provides:

- **Security**: EXIF data stripping to remove sensitive metadata
- **Performance**: Multiple responsive sizes and WebP optimization
- **Automation**: Command-line tools and web interface
- **Integration**: Seamless integration with the evidence gallery

## Workflow Steps

### 1. Prepare Raw Images

Place your original evidence images in the raw directory:

```
apps/web/public/evidence/raw/
├── email-screenshot-1.jpg
├── email-screenshot-2.png
├── document-scan.tiff
└── phone-call-log.jpeg
```

### 2. Process Images

Run the automated processing script:

```bash
cd apps/web
npm run process-evidence
```

This will:
- Strip EXIF data for privacy
- Convert to WebP format
- Generate responsive sizes (320px, 640px, 1280px)
- Create optimized full-size versions
- Generate configuration file

### 3. Verify Output

Check the processed images:

```
apps/web/public/evidence/
├── email-screenshot-1.webp          # Full-size
├── email-screenshot-1-320w.webp     # Mobile
├── email-screenshot-1-640w.webp     # Tablet  
├── email-screenshot-1-1280w.webp    # Desktop
├── email-screenshot-2.webp
├── email-screenshot-2-320w.webp
├── email-screenshot-2-640w.webp
├── email-screenshot-2-1280w.webp
└── image-config.json                # Configuration
```

### 4. Update Article Content

Update your `content/article.mdx` frontmatter:

```yaml
evidence: [
  {
    "src": "/evidence/email-screenshot-1.webp",
    "type": "image",
    "caption": "Initial support request showing 7-day delay",
    "alt": "Screenshot of AppleCare email with timestamp showing delayed response"
  },
  {
    "src": "/evidence/email-screenshot-2.webp",
    "type": "image", 
    "caption": "Escalation email with no follow-up",
    "alt": "Screenshot of supervisor escalation email with no resolution"
  }
]
```

### 5. Build and Deploy

The optimized images will be automatically included in your build:

```bash
npm run build
```

## File Naming Convention

The processing script follows this naming pattern:

- **Original**: `email-screenshot-1.jpg`
- **Full-size**: `email-screenshot-1.webp`
- **Mobile**: `email-screenshot-1-320w.webp`
- **Tablet**: `email-screenshot-1-640w.webp`
- **Desktop**: `email-screenshot-1-1280w.webp`

## Configuration File

The `image-config.json` file contains metadata for all processed images:

```json
{
  "email-screenshot-1": {
    "original": {
      "src": "/evidence/email-screenshot-1.webp",
      "width": 1920,
      "height": 1080,
      "size": 245760
    },
    "responsive": {
      "320": {
        "src": "/evidence/email-screenshot-1-320w.webp",
        "width": 320,
        "height": 180,
        "size": 12480
      },
      "640": {
        "src": "/evidence/email-screenshot-1-640w.webp", 
        "width": 640,
        "height": 360,
        "size": 35840
      },
      "1280": {
        "src": "/evidence/email-screenshot-1-1280w.webp",
        "width": 1280,
        "height": 720,
        "size": 122880
      }
    }
  }
}
```

## Integration with Components

### EvidenceGallery Component

The gallery automatically uses optimized images:

```tsx
// The component will automatically use responsive images
// if they're available in the configuration
<EvidenceGallery evidence={frontmatter.evidence} />
```

### ResponsiveImage Component

For custom image usage:

```tsx
import ResponsiveImage from '@/components/ResponsiveImage';

<ResponsiveImage
  src="/evidence/email-screenshot-1.webp"
  alt="AppleCare support email"
  sizes="(max-width: 640px) 320px, (max-width: 1280px) 640px, 1280px"
/>
```

### Image Utilities

Use the utility functions for advanced scenarios:

```tsx
import { getOptimizedImageSrc, getImageDimensions } from '@/lib/image-config';

// Get specific size
const mobileImage = getOptimizedImageSrc('/evidence/email-1.webp', 320);

// Get dimensions
const dimensions = getImageDimensions('/evidence/email-1.webp');
```

## Performance Benefits

### File Size Reduction

Typical savings from the optimization process:

- **JPEG to WebP**: 25-35% smaller files
- **PNG to WebP**: 50-80% smaller files
- **Responsive sizes**: 60-90% smaller for mobile devices

### Loading Performance

- **Responsive images**: Appropriate size for each device
- **WebP format**: Faster decoding and rendering
- **Lazy loading**: Images load only when needed
- **Proper dimensions**: Prevents layout shift

## Security Features

### EXIF Data Removal

The processing removes sensitive metadata:

- GPS coordinates
- Camera make/model
- Software information
- User comments
- Timestamps
- Device settings

### Example EXIF Data Stripped

Before processing:
```
GPS Latitude: 37.7749° N
GPS Longitude: 122.4194° W
Camera Make: Apple
Camera Model: iPhone 14 Pro
Software: iOS 16.1
Date Taken: 2024-01-15 14:30:22
```

After processing:
```
[No EXIF data present]
```

## Troubleshooting

### Common Issues

**Node.js Version Error**
```
Error: Could not load the "sharp" module
```
Solution: Upgrade to Node.js 18.17.0+ or 20.3.0+

**No Images Found**
```
No supported image files found in: public/evidence/raw
```
Solution: Place images in the correct directory

**Processing Fails**
```
Error processing image-name.jpg: Invalid input
```
Solution: Check image format and file corruption

### Manual Processing

If automated processing fails, you can manually optimize images:

1. **Online Tools**:
   - [Squoosh](https://squoosh.app/) - Google's image optimizer
   - [TinyPNG](https://tinypng.com/) - PNG/JPEG optimizer
   - [Convertio](https://convertio.co/) - Format converter

2. **Command Line Tools**:
   ```bash
   # Using ImageMagick
   convert input.jpg -strip -quality 85 -resize 640x output.webp
   
   # Using cwebp
   cwebp -q 85 input.jpg -o output.webp
   ```

3. **EXIF Removal**:
   ```bash
   # Using exiftool
   exiftool -all= input.jpg
   ```

## Best Practices

### Image Preparation

- Use high-quality source images (1920px+ width)
- Avoid heavily compressed images as sources
- Ensure images are properly oriented
- Use descriptive filenames

### File Organization

- Keep raw images in the `raw/` directory
- Don't commit raw images to version control
- Use `.gitignore` for the raw directory
- Document image sources and permissions

### Content Guidelines

- Write descriptive alt text for accessibility
- Include context in captions
- Verify image content doesn't contain sensitive information
- Consider redacting personal information before processing

### Performance Optimization

- Use appropriate image sizes for content
- Implement lazy loading for below-the-fold images
- Consider using a CDN for image delivery
- Monitor Core Web Vitals impact

## Development

### Adding New Sizes

To add new responsive sizes, edit `scripts/process-evidence.js`:

```javascript
const SIZES = [320, 640, 1280, 1920]; // Add 1920px size
```

### Custom Processing

For special processing needs, extend the script:

```javascript
// Add custom processing step
await baseImage
  .clone()
  .blur(2) // Add blur effect
  .webp({ quality: QUALITY })
  .toFile(blurredOutputPath);
```

### Testing

Run the test suite to verify functionality:

```bash
npm test
```

The tests cover:
- File format validation
- Size calculation
- Path generation
- Configuration loading

This comprehensive workflow ensures your evidence images are secure, optimized, and ready for production deployment.