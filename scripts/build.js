const fs = require('fs');
const path = require('path');

const rootDir = path.join(__dirname, '..');
const wwwDir = path.join(rootDir, 'www');

if (!fs.existsSync(wwwDir)) {
  fs.mkdirSync(wwwDir, { recursive: true });
}

const filesToCopy = [
  'index.html',
  'manifest.json',
  'sw.js',
  'schema.sql',
  'README.md'
];

filesToCopy.forEach(file => {
  const src = path.join(rootDir, file);
  const dest = path.join(wwwDir, file);
  if (fs.existsSync(src)) {
    fs.copyFileSync(src, dest);
    console.log(`[BUILD] Copiado ${file} -> www/${file}`);
  }
});

// Copiar pasta icons
const iconsSrc = path.join(rootDir, 'icons');
const iconsDest = path.join(wwwDir, 'icons');
if (fs.existsSync(iconsSrc)) {
  if (!fs.existsSync(iconsDest)) {
    fs.mkdirSync(iconsDest, { recursive: true });
  }
  fs.readdirSync(iconsSrc).forEach(icon => {
    fs.copyFileSync(path.join(iconsSrc, icon), path.join(iconsDest, icon));
  });
  console.log(`[BUILD] Copiada pasta icons -> www/icons/`);
}

console.log('✅ Build para Capacitor finalizada com sucesso na pasta www/!');
