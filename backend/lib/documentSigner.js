const ExcelJS = require('exceljs');
const fs = require('fs').promises;
const path = require('path');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

class DocumentSigner {
  constructor(firmaPath = null) {
    // Usar firma por defecto desde .env o fallback
    this.firmaPath = firmaPath || 
                    process.env.DEFAULT_SIGNATURE || 
                    path.join(process.env.SIGNATURES_PATH || 'signatures', 'default_signature.png');
  }

  /**
   * Firmar documento Word o Excel
   * @param {string} filePath - Ruta del archivo a firmar
   * @param {string} outputPath - Ruta donde guardar el archivo firmado
   * @param {string} signerName - Nombre del firmante
   * @param {string} signatureImagePath - Ruta de la imagen de firma (opcional)
   * @returns {Promise<string>} - Ruta del archivo firmado
   */
  async signDocument(filePath, outputPath, signerName, signatureImagePath = null) {
    const ext = path.extname(filePath).toLowerCase();
    const finalSignaturePath = signatureImagePath || this.firmaPath;

    // Verificar que existe la imagen de firma
    try {
      await fs.access(finalSignaturePath);
    } catch (error) {
      throw new Error(`Imagen de firma no encontrada: ${finalSignaturePath}`);
    }

    if (ext === '.xlsx' || ext === '.xls') {
      return await this.signExcel(filePath, outputPath, finalSignaturePath, signerName);
    } else if (ext === '.docx' || ext === '.doc') {
      return await this.signWord(filePath, outputPath, finalSignaturePath, signerName);
    } else {
      throw new Error(`Formato no soportado: ${ext}. Solo se admiten .docx, .doc, .xlsx, .xls`);
    }
  }

  /**
   * Firmar archivo Excel usando ExcelJS
   */
  async signExcel(filePath, outputPath, signaturePath, signerName) {
    try {
      const workbook = new ExcelJS.Workbook();
      await workbook.xlsx.readFile(filePath);

      const sheet = workbook.worksheets[0];
      if (!sheet) {
        throw new Error('El archivo Excel no tiene hojas de trabajo');
      }

      // Agregar imagen de firma
      const imageId = workbook.addImage({
        filename: signaturePath,
        extension: 'png',
      });

      // Insertar firma en la celda B10:E15 (ajustable)
      sheet.addImage(imageId, {
        tl: { col: 1, row: 9 },   // top-left (B10)
        br: { col: 4, row: 14 },  // bottom-right (E15)
      });

      // Agregar información del firmante
      const lastRow = sheet.rowCount + 2;
      sheet.getCell(`A${lastRow}`).value = `Firmado por: ${signerName}`;
      sheet.getCell(`A${lastRow + 1}`).value = `Fecha: ${new Date().toLocaleString('es-ES')}`;

      await workbook.xlsx.writeFile(outputPath);
      return outputPath;

    } catch (error) {
      throw new Error(`Error firmando Excel: ${error.message}`);
    }
  }

  /**
   * Firmar archivo Word usando Python script
   */
  async signWord(filePath, outputPath, signaturePath, signerName) {
    try {
      const scriptPath = path.join(__dirname, '..', 'scripts', 'firmar_word.py');
      
      // Verificar que existe el script Python
      try {
        await fs.access(scriptPath);
      } catch (error) {
        throw new Error(`Script Python no encontrado: ${scriptPath}`);
      }

      const command = `python3 "${scriptPath}" "${filePath}" "${signaturePath}" "${outputPath}" "${signerName}"`;
      
      const { stdout, stderr } = await execAsync(command);
      
      if (stderr && !stderr.includes('Warning')) {
        throw new Error(`Error en script Python: ${stderr}`);
      }

      // Verificar que se creó el archivo de salida
      try {
        await fs.access(outputPath);
        return outputPath;
      } catch (error) {
        throw new Error('El archivo firmado no se generó correctamente');
      }

    } catch (error) {
      throw new Error(`Error firmando Word: ${error.message}`);
    }
  }

  /**
   * Obtener información del documento
   */
  async getDocumentInfo(filePath) {
    const ext = path.extname(filePath).toLowerCase();
    const stats = await fs.stat(filePath);

    const info = {
      extension: ext,
      size: stats.size,
      lastModified: stats.mtime,
      canSign: ['.docx', '.doc', '.xlsx', '.xls'].includes(ext)
    };

    if (ext === '.xlsx' || ext === '.xls') {
      try {
        const workbook = new ExcelJS.Workbook();
        await workbook.xlsx.readFile(filePath);
        info.sheets = workbook.worksheets.length;
        info.sheetNames = workbook.worksheets.map(sheet => sheet.name);
      } catch (error) {
        info.error = 'No se pudo leer el archivo Excel';
      }
    }

    return info;
  }
}

module.exports = DocumentSigner;
