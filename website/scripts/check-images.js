import fs from 'fs';
import path from 'path';

const publicDir = path.join(process.cwd(), 'public');
const dataDir = path.join(publicDir, 'data');

let hasErrors = false;

function checkImagesInObject(obj, filePath) {
  if (typeof obj === 'string') {
    if (obj.startsWith('/')) {
      const ext = path.extname(obj).toLowerCase();
      const imageExts = ['.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp'];
      
      if (imageExts.includes(ext) || obj.startsWith('/data/assets/')) {
        const fullPath = path.join(publicDir, obj);
        if (!fs.existsSync(fullPath)) {
          console.error(`❌ Error: File not found: ${obj}`);
          console.error(`   Referenced in: ${filePath}`);
          hasErrors = true;
        }
      }
    }
  } else if (Array.isArray(obj)) {
    for (const item of obj) {
      checkImagesInObject(item, filePath);
    }
  } else if (obj !== null && typeof obj === 'object') {
    for (const key of Object.keys(obj)) {
      checkImagesInObject(obj[key], filePath);
    }
  }
}

function traverseDirectory(dir) {
  if (!fs.existsSync(dir)) {
    console.log(`Directory ${dir} does not exist. Skipping...`);
    return;
  }
  
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const fullPath = path.join(dir, file);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      traverseDirectory(fullPath);
    } else if (fullPath.endsWith('.json')) {
      const content = fs.readFileSync(fullPath, 'utf8');
      try {
        const parsed = JSON.parse(content);
        checkImagesInObject(parsed, path.relative(process.cwd(), fullPath));
      } catch (e) {
        console.error(`❌ Error parsing JSON in ${fullPath}:`, e.message);
        hasErrors = true;
      }
    }
  }
}

console.log('Checking JSON files for valid local image paths...');
traverseDirectory(dataDir);

if (hasErrors) {
  console.error('\n🚨 Image path validation failed. See errors above.');
  process.exit(1);
} else {
  console.log('\n✅ All local image paths in JSON files are valid!');
}
