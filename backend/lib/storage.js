const fs = require('fs');
const path = require('path');

const ensureDirs = (uploadDir, signedDir) => {
  if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
  if (!fs.existsSync(signedDir)) fs.mkdirSync(signedDir, { recursive: true });
};

const resolvePath = (p) => path.resolve(p);

module.exports = {
  ensureDirs,
  resolvePath
};
