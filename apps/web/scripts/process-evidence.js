#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Check Node.js version
const nodeVersion = process.version;
const majorVersion = parseInt(nodeVersion.slice(1).split('.')[0]);

if (majorVersion < 18 || (majorVersion === 18 && !nodeVersion.match(/^v18\.1[7-9]/) && !nodeVersion.match(/^v18\.[2-9]/))) {
  console.error('❌ Node.js version requirement not met');
  console.error(`   Current: ${nodeVersion}`);
  console.error('   Required: ^18.17.0 || ^20.3.0 || >=21.0.0');
  console.error('\nPlease upgrade Node.js to use the Sharp image processing library.');
  console.error('For now, you can manually optimize images using online tools or other software.');
  process.exit(1);
}

let sharp;
try {
  sharp = require('sharp');
} catch (error) {
  console.error('❌ Sharp library not available');
  console.error('   Run: npm install sharp');
  console.error('   Note: Requires Node.js ^18.17.0 || ^20.3.0 || >=21.0.0');
  process.exit(1);
}

// Configuration
const INPUT_DIR = path.join(__dirname, '../public/evidence/raw');
const OUTPUT_DIR = path.join(__dirname, '../public/evidence');
const SIZES = [320, 640, 1280];
const QUALITY = 85;

// Supported image formats
const SUPPORTED_FORMATS = ['.jpg', '.jpeg', '.png', '.tiff', '.webp'];

/**
 * Ensure directory exists
 */
function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

/**
 * Get file size in bytes
 */
function getFileSize(filePath) {
  const stats = fs.statSync(filePath);
  return stats.size;
}

/**
 * Format file size for display
 */
function formatFileSize(bytes) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

/**
 * Strip EXIF data and get image metadata
 */
async function getImageInfo(inputPath) {
  const image = sharp(inputPath);
  const metadata = await image.metadata();
  
  return {
    width: metadata.width,
    height: metadata.height,
    format: metadata.format,
    hasExif: !!metadata.exif,
    hasIcc: !!metadata.icc,
  };
}

/**
 * Process a single image file
 */
async function processImage(inputPath, outputDir, filename) {
  console.log(`\nProcessing: ${filename}`);
  
  try {
    // Get original image info
    const originalInfo = await getImageInfo(inputPath);
    const originalSize = getFileSize(inputPath);
    
    console.log(`  Original: ${originalInfo.width}x${originalInfo.height} ${originalInfo.format.toUpperCase()}`);
    console.log(`  Size: ${formatFileSize(originalSize)}`);
    console.log(`  EXIF data: ${originalInfo.hasExif ? 'Yes (will be stripped)' : 'No'}`);
    
    const baseName = path.parse(filename).name;
    const processedFiles = [];
    
    // Create base sharp instance with EXIF stripped
    const baseImage = sharp(inputPath)
      .rotate() // Auto-rotate based on EXIF orientation, then strip EXIF
      .withMetadata(false); // Strip all metadata including EXIF
    
    // Generate WebP versions at different sizes
    for (const size of SIZES) {
      const outputPath = path.join(outputDir, `${baseName}-${size}w.webp`);
      
      await baseImage
        .clone()
        .resize(size, null, {
          withoutEnlargement: true,
          fit: 'inside'
        })
        .webp({ quality: QUALITY })
        .toFile(outputPath);
      
      const processedSize = getFileSize(outputPath);
      const processedInfo = await getImageInfo(outputPath);
      
      console.log(`  Generated: ${baseName}-${size}w.webp (${processedInfo.width}x${processedInfo.height}) - ${formatFileSize(processedSize)}`);
      
      processedFiles.push({
        size,
        path: outputPath,
        width: processedInfo.width,
        height: processedInfo.height,
        fileSize: processedSize
      });
    }
    
    // Also create a full-size WebP version
    const fullSizePath = path.join(outputDir, `${baseName}.webp`);
    await baseImage
      .clone()
      .webp({ quality: QUALITY })
      .toFile(fullSizePath);
    
    const fullSizeInfo = await getImageInfo(fullSizePath);
    const fullSizeFileSize = getFileSize(fullSizePath);
    
    console.log(`  Generated: ${baseName}.webp (${fullSizeInfo.width}x${fullSizeInfo.height}) - ${formatFileSize(fullSizeFileSize)}`);
    
    // Calculate total savings
    const totalProcessedSize = processedFiles.reduce((sum, file) => sum + file.fileSize, 0) + fullSizeFileSize;
    const savings = ((originalSize - totalProcessedSize) / originalSize * 100).toFixed(1);
    
    console.log(`  Total savings: ${savings}% (${formatFileSize(originalSize - totalProcessedSize)})`);
    
    return {
      original: {
        path: inputPath,
        width: originalInfo.width,
        height: originalInfo.height,
        size: originalSize
      },
      processed: processedFiles,
      fullSize: {
        path: fullSizePath,
        width: fullSizeInfo.width,
        height: fullSizeInfo.height,
        size: fullSizeFileSize
      }
    };
    
  } catch (error) {
    console.error(`  Error processing ${filename}:`, error.message);
    return null;
  }
}

/**
 * Generate responsive image configuration
 */
function generateImageConfig(results) {
  const config = {};
  
  results.forEach(result => {
    if (!result) return;
    
    const baseName = path.parse(result.original.path).name;
    config[baseName] = {
      original: {
        src: `/evidence/${path.basename(result.fullSize.path)}`,
        width: result.fullSize.width,
        height: result.fullSize.height,
        size: result.fullSize.size
      },
      responsive: {}
    };
    
    result.processed.forEach(processed => {
      config[baseName].responsive[processed.size] = {
        src: `/evidence/${path.basename(processed.path)}`,
        width: processed.width,
        height: processed.height,
        size: processed.fileSize
      };
    });
  });
  
  return config;
}

/**
 * Main processing function
 */
async function main() {
  console.log('🖼️  Evidence Image Processor');
  console.log('============================\n');
  
  // Ensure directories exist
  ensureDir(INPUT_DIR);
  ensureDir(OUTPUT_DIR);
  
  // Check if input directory has files
  if (!fs.existsSync(INPUT_DIR)) {
    console.log(`📁 Creating input directory: ${INPUT_DIR}`);
    console.log('   Place your raw evidence images in this directory and run the script again.');
    return;
  }
  
  // Get all image files from input directory
  const files = fs.readdirSync(INPUT_DIR)
    .filter(file => {
      const ext = path.extname(file).toLowerCase();
      return SUPPORTED_FORMATS.includes(ext);
    });
  
  if (files.length === 0) {
    console.log(`📁 No supported image files found in: ${INPUT_DIR}`);
    console.log(`   Supported formats: ${SUPPORTED_FORMATS.join(', ')}`);
    console.log('   Place your raw evidence images in this directory and run the script again.');
    return;
  }
  
  console.log(`Found ${files.length} image(s) to process:`);
  files.forEach(file => console.log(`  - ${file}`));
  console.log('');
  
  // Process all images
  const results = [];
  for (const file of files) {
    const inputPath = path.join(INPUT_DIR, file);
    const result = await processImage(inputPath, OUTPUT_DIR, file);
    results.push(result);
  }
  
  // Generate configuration file
  const config = generateImageConfig(results.filter(r => r !== null));
  const configPath = path.join(OUTPUT_DIR, 'image-config.json');
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
  
  console.log(`\n📄 Generated image configuration: ${configPath}`);
  console.log('\n✅ Processing complete!');
  console.log('\nNext steps:');
  console.log('1. Update your article.mdx frontmatter to reference the optimized images');
  console.log('2. Use the responsive images in your EvidenceGallery component');
  console.log('3. Consider implementing a picture element for better performance');
}

// Handle command line usage
if (require.main === module) {
  main().catch(error => {
    console.error('❌ Error:', error.message);
    process.exit(1);
  });
}

module.exports = {
  processImage,
  generateImageConfig,
  SIZES,
  QUALITY
};