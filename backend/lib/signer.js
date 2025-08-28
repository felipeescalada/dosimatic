const fs = require('fs');
const { PDFDocument, StandardFonts, rgb } = require('pdf-lib');
const pdfParse = require('pdf-parse');

/**
 * Busca placeholders @aprobador, @revisor en el PDF e inserta imágenes de firma
 */
async function signPdfWithImage(inputPdfPath, outputPdfPath, signerName, signatureImagePath, signatureType = 'FIRMADO', date = new Date()) {
  const bytes = fs.readFileSync(inputPdfPath);
  const pdfDoc = await PDFDocument.load(bytes);
  const pages = pdfDoc.getPages();
  const font = await pdfDoc.embedFont(StandardFonts.Helvetica);

  // Cargar imagen de firma si existe
  let signatureImage = null;
  if (signatureImagePath && fs.existsSync(signatureImagePath)) {
    const imageBytes = fs.readFileSync(signatureImagePath);
    const imageType = signatureImagePath.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    signatureImage = imageType === 'png' 
      ? await pdfDoc.embedPng(imageBytes)
      : await pdfDoc.embedJpg(imageBytes);
  }

  // Extraer texto del PDF para encontrar placeholders
  let pdfText = '';
  try {
    const pdfData = await pdfParse(bytes);
    pdfText = pdfData.text;
  } catch (error) {
    console.warn('No se pudo extraer texto del PDF:', error.message);
  }

  // Definir placeholders según el tipo de firma
  const getPlaceholderForType = (type) => {
    switch (type) {
      case 'APROBADO':
        return '@aprobador';
      case 'REVISADO':
        return '@revisor';
      case 'FIRMADO':
      default:
        return '@firmante';
    }
  };

  const targetPlaceholder = getPlaceholderForType(signatureType);
  let signaturesInserted = 0;

  // Buscar placeholder en el texto extraído
  if (pdfText.includes(targetPlaceholder)) {
    // Si encontramos el placeholder, buscar su posición aproximada en las páginas
    for (let pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      const page = pages[pageIndex];
      const { width, height } = page.getSize();
      
      // Calcular posición basada en el tipo de placeholder
      const position = calculatePlaceholderPosition(width, height, targetPlaceholder, pageIndex);
      
      if (signatureImage) {
        // Insertar imagen de firma
        const signatureWidth = 120;
        const signatureHeight = 60;
        
        page.drawImage(signatureImage, {
          x: position.x,
          y: position.y,
          width: signatureWidth,
          height: signatureHeight,
        });
      }
      
      // Agregar texto descriptivo
      const statusText = getStatusText(signatureType);
      const signatureText = `${statusText}: ${signerName}`;
      const dateText = date.toISOString().slice(0,10);
      
      page.drawText(signatureText, {
        x: position.x,
        y: position.y - 15,
        size: 10,
        font,
        color: rgb(0, 0, 0.8),
      });
      
      page.drawText(dateText, {
        x: position.x,
        y: position.y - 30,
        size: 8,
        font,
        color: rgb(0.5, 0.5, 0.5),
      });
      
      signaturesInserted++;
      break; // Solo insertar una vez por tipo
    }
  }

  // Si no se encontró el placeholder, usar posición por defecto
  if (signaturesInserted === 0) {
    const lastPage = pages[pages.length - 1];
    const { width, height } = lastPage.getSize();
    
    const defaultPosition = getDefaultPosition(width, height, signatureType);
    
    if (signatureImage) {
      lastPage.drawImage(signatureImage, {
        x: defaultPosition.x,
        y: defaultPosition.y,
        width: 120,
        height: 60,
      });
    }
    
    // Agregar texto de firma
    const statusText = getStatusText(signatureType);
    const signatureText = `${statusText}: ${signerName} - ${date.toISOString().slice(0,19).replace('T',' ')}`;
    lastPage.drawText(signatureText, {
      x: defaultPosition.x,
      y: defaultPosition.y - 15,
      size: 10,
      font,
    });
    
    signaturesInserted = 1;
  }

  const pdfBytes = await pdfDoc.save();
  fs.writeFileSync(outputPdfPath, pdfBytes);
  
  return {
    outputPath: outputPdfPath,
    signaturesInserted,
    hasSignatureImage: !!signatureImage,
    signatureType,
    placeholderFound: signaturesInserted > 0 && pdfText.includes(targetPlaceholder)
  };
}

/**
 * Calcula posición del placeholder basado en patrones comunes de documentos
 */
function calculatePlaceholderPosition(width, height, placeholder, pageIndex) {
  switch (placeholder) {
    case '@aprobador':
      return {
        x: width - 200, // Derecha
        y: height - 200 // Parte superior
      };
    case '@revisor':
      return {
        x: 50, // Izquierda
        y: height - 200 // Parte superior
      };
    case '@firmante':
    default:
      return {
        x: width / 2 - 60, // Centro
        y: 150 // Parte inferior
      };
  }
}

/**
 * Posiciones por defecto si no se encuentra placeholder
 */
function getDefaultPosition(width, height, signatureType) {
  switch (signatureType) {
    case 'APROBADO':
      return { x: width - 200, y: 200 };
    case 'REVISADO':
      return { x: 50, y: 200 };
    case 'FIRMADO':
    default:
      return { x: width / 2 - 60, y: 150 };
  }
}

/**
 * Obtiene el texto de estado basado en el tipo de firma
 */
function getStatusText(signatureType) {
  switch (signatureType) {
    case 'APROBADO':
      return 'Aprobado por';
    case 'REVISADO':
      return 'Revisado por';
    case 'FIRMADO':
    default:
      return 'Firmado por';
  }
}

/**
 * Función original mantenida para compatibilidad
 */
async function signPdfFooter(inputPdfPath, outputPdfPath, signerName, date = new Date()) {
  return await signPdfWithImage(inputPdfPath, outputPdfPath, signerName, null, 'FIRMADO', date);
}

module.exports = {
  signPdfFooter,
  signPdfWithImage
};
