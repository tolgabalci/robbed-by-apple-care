const fs = require('fs');
const path = require('path');

console.log('🔍 Validating project setup...\n');

// Check required files
const requiredFiles = [
  'package.json',
  'pnpm-workspace.yaml',
  'apps/web/package.json',
  'apps/web/next.config.js',
  'apps/web/tailwind.config.js',
  'apps/web/tsconfig.json',
  'apps/web/app/layout.tsx',
  'apps/web/app/page.tsx',
  'apps/web/app/globals.css',
  'infra/terraform/main.tf',
  'apps/forum-provisioning/docker-compose.yml'
];

let allFilesExist = true;

requiredFiles.forEach(file => {
  if (fs.existsSync(file)) {
    console.log(`✅ ${file}`);
  } else {
    console.log(`❌ ${file} - MISSING`);
    allFilesExist = false;
  }
});

// Check package.json structure
try {
  const rootPkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
  const webPkg = JSON.parse(fs.readFileSync('apps/web/package.json', 'utf8'));
  
  console.log('\n📦 Package validation:');
  console.log(`✅ Root package name: ${rootPkg.name}`);
  console.log(`✅ Web app package name: ${webPkg.name}`);
  console.log(`✅ Next.js version: ${webPkg.dependencies.next}`);
  console.log(`✅ React version: ${webPkg.dependencies.react}`);
} catch (error) {
  console.log(`❌ Package.json validation failed: ${error.message}`);
  allFilesExist = false;
}

// Check Next.js config
try {
  const nextConfig = fs.readFileSync('apps/web/next.config.js', 'utf8');
  if (nextConfig.includes('withMDX') && nextConfig.includes('output: \'export\'')) {
    console.log('✅ Next.js config includes MDX and static export');
  } else {
    console.log('❌ Next.js config missing required settings');
  }
} catch (error) {
  console.log(`❌ Next.js config validation failed: ${error.message}`);
}

// Check security headers
try {
  const nextConfig = fs.readFileSync('apps/web/next.config.js', 'utf8');
  const securityHeaders = [
    'Content-Security-Policy',
    'Strict-Transport-Security',
    'X-Frame-Options',
    'X-Content-Type-Options',
    'Referrer-Policy',
    'Permissions-Policy'
  ];
  
  const missingHeaders = securityHeaders.filter(header => !nextConfig.includes(header));
  
  if (missingHeaders.length === 0) {
    console.log('✅ All security headers configured');
  } else {
    console.log(`❌ Missing security headers: ${missingHeaders.join(', ')}`);
  }
} catch (error) {
  console.log(`❌ Security headers validation failed: ${error.message}`);
}

console.log('\n🏗️  Project structure validation:');
const directories = [
  'apps/web/app',
  'apps/web/components',
  'apps/web/public',
  'apps/forum-provisioning',
  'infra/terraform'
];

directories.forEach(dir => {
  if (fs.existsSync(dir)) {
    console.log(`✅ ${dir}/`);
  } else {
    console.log(`❌ ${dir}/ - MISSING`);
  }
});

if (allFilesExist) {
  console.log('\n🎉 Project setup validation completed successfully!');
  console.log('\nNext steps:');
  console.log('1. Install dependencies: npm install (in apps/web)');
  console.log('2. Start development: npm run dev (in apps/web)');
  console.log('3. Deploy infrastructure: terraform init && terraform apply (in infra/terraform)');
} else {
  console.log('\n❌ Project setup has issues that need to be resolved.');
  process.exit(1);
}