# Evidence Image Processing

This directory contains scripts for processing and optimizing evidence images for the RobbedByAppleCare website.

## Requirements

- Node.js ^18.17.0 || ^20.3.0 || >=21.0.0
- Sharp image processing library

## Scripts

### `process-evidence.js`

Automatically processes raw evidence images with the following features:

- **EXIF Data Stripping**: Removes all metadata for privacy and security
- **Format Conversion**: Converts images to optimized WebP format
- **Responsive Sizes**: Generates multiple sizes (320px, 640px, 1280px, full-size)
- **Compression**: Applies 85% quality compression for optimal file size
- **Auto-rotation**: Handles EXIF orientation data before stripping

#### Usage

1. Place raw images in `public/evidence/raw/`
2. Run the processing script:
   ```bash
   npm run process-evidence
   ```
3. Optimized images will be saved to `public/evidence/`
4. A configuration file `image-config.json` will be generated

#### Supported Formats

- JPEG (.jpg, .jpeg)
- PNG (.png)
- TIFF (.tiff)
- WebP (.webp)

### `evidence-manager.html`

A web-based interface for managing evidence images:

- Drag-and-drop file upload
- File preview and validation
- Processing status tracking
- Instructions and documentation

#### Usage

```bash
npm run evidence-manager
```

This opens the HTML interface in your default browser.

## File Structure

```
public/evidence/
├── raw/                    # Place original images here
│   ├── email-screenshot-1.jpg
│   ├── email-screenshot-2.png
│   └── document-scan.tiff
├── email-screenshot-1.webp      # Full-size optimized
├── email-screenshot-1-320w.webp # Mobile size
├── email-screenshot-1-640w.webp # Tablet size
├── email-screenshot-1-1280w.webp # Desktop size
└── image-config.json       # Generated configuration
```

## Integration with Article

After processing images, update your `content/article.mdx` frontmatter:

```yaml
evidence: [
  {
    "src": "/evidence/email-screenshot-1.webp",
    "type": "image",
    "caption": "Initial support request email",
    "alt": "Screenshot showing AppleCare support email"
  }
]
```

## Security Features

- **EXIF Stripping**: Removes potentially sensitive metadata including:
  - GPS coordinates
  - Camera information
  - Timestamps
  - Software details
  - User comments

- **Format Standardization**: Converts all images to WebP for consistency

- **Size Optimization**: Reduces file sizes while maintaining quality

## Performance Benefits

- **Responsive Images**: Multiple sizes for different screen resolutions
- **Modern Format**: WebP provides 25-35% better compression than JPEG
- **Lazy Loading**: Optimized for use with lazy loading implementations
- **CDN Ready**: Optimized files ready for CDN distribution

## Troubleshooting

### Node.js Version Issues

If you encounter Sharp installation issues:

1. Check your Node.js version: `node --version`
2. Upgrade to a supported version (18.17.0+, 20.3.0+, or 21.0.0+)
3. Reinstall Sharp: `npm install sharp`

### Alternative Processing

If you can't use the automated script:

1. Use online tools like [Squoosh](https://squoosh.app/)
2. Manually convert to WebP format
3. Generate multiple sizes (320px, 640px, 1280px)
4. Strip EXIF data using tools like `exiftool`
5. Update the article frontmatter manually

### File Size Guidelines

- Mobile (320px): Target < 50KB
- Tablet (640px): Target < 150KB  
- Desktop (1280px): Target < 300KB
- Full-size: Target < 500KB

## Development

To modify the processing script:

1. Edit `process-evidence.js`
2. Adjust `SIZES`, `QUALITY`, or other constants
3. Test with sample images
4. Update documentation as needed

The script is modular and exports functions for testing:

```javascript
const { processImage, generateImageConfig } = require('./process-evidence.js');
```