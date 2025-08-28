const fs = require('fs');
const path = require('path');
const libre = require('libreoffice-convert');

// Configure LibreOffice path for different environments
const os = require('os');

// Set LibreOffice path based on environment
if (process.env.NODE_ENV === 'production' || process.env.DOCKER_ENV) {
  // Docker/Linux environment
  process.env.SOFFICE_PATH = '/usr/bin/soffice';
} else if (os.platform() === 'win32') {
  // Windows development environment
  const possiblePaths = [
    'C:\\Program Files\\LibreOffice\\program\\soffice.exe',
    'C:\\Program Files (x86)\\LibreOffice\\program\\soffice.exe',
    'C:\\Users\\' + os.userInfo().username + '\\AppData\\Local\\Programs\\LibreOffice\\program\\soffice.exe'
  ];
  
  for (const sofficePath of possiblePaths) {
    if (fs.existsSync(sofficePath)) {
      process.env.SOFFICE_PATH = sofficePath;
      console.log(`LibreOffice found at: ${sofficePath}`);
      break;
    }
  }
  
  if (!process.env.SOFFICE_PATH) {
    console.warn('LibreOffice not found. Please install LibreOffice from https://www.libreoffice.org/download/');
  }
} else {
  // Linux/Mac development environment
  process.env.SOFFICE_PATH = '/usr/bin/soffice';
}

async function docxToPdf(inputPath, outputPath) {
  const ext = '.pdf';
  const docxBuf = fs.readFileSync(inputPath);

  return new Promise((resolve, reject) => {
    libre.convert(docxBuf, ext, undefined, (err, done) => {
      if (err) return reject(err);
      fs.writeFileSync(outputPath, done);
      resolve(outputPath);
    });
  });
}

function changeExtToPdf(filePath, outDir) {
  const base = path.basename(filePath, path.extname(filePath));
  return path.join(outDir, `${base}.pdf`);
}

module.exports = {
  docxToPdf,
  changeExtToPdf
};
