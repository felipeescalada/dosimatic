#!/usr/bin/env node

/**
 * Sistema de Gestión Documental - Servidor Principal
 * 
 * Funcionalidades:
 * - Upload de documentos Word (.docx)
 * - Conversión automática DOCX → PDF
 * - Firma digital con pie de página
 * - Versionado de documentos
 * - Descarga de archivos originales y firmados
 */

import 'dotenv/config';
import express from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { v4 as uuidv4 } from 'uuid';
import mime from 'mime-types';
import swaggerJsdoc from 'swagger-jsdoc';
import swaggerUi from 'swagger-ui-express';

import { pool } from './lib/db.js';
import { ensureDirs, resolvePath } from './lib/storage.js';
import { docxToPdf, changeExtToPdf } from './lib/convert.js';
import { signPdfFooter } from './lib/signer.js';

const app = express();
app.use(express.json());

// Configuración de directorios
const UPLOAD_DIR = resolvePath(process.env.UPLOAD_DIR || './uploads');
const SIGNED_DIR = resolvePath(process.env.SIGNED_DIR || './signed');
ensureDirs(UPLOAD_DIR, SIGNED_DIR);

// Configuración de Multer para almacenamiento
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOAD_DIR),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || `.${mime.extension(file.mimetype) || 'bin'}`;
    cb(null, `${uuidv4()}${ext}`);
  }
});
const upload = multer({ storage });

// Helper para obtener siguiente versión
async function nextVersion(documentId) {
  const { rows } = await pool.query(
    'SELECT COALESCE(MAX(version),0)+1 AS v FROM document_versions WHERE document_id=$1',
    [documentId]
  );
  return rows[0].v;
}

// Configuración de Swagger
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Sistema de Gestión Documental API',
      version: '1.0.0',
      description: 'API para gestión de documentos con upload, conversión DOCX→PDF y firma digital',
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Servidor de desarrollo',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
    },
  },
  apis: ['./server.js'], // Este mismo archivo
};

const specs = swaggerJsdoc(swaggerOptions);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs, {
  explorer: true,
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'Sistema Documental API'
}));

// ================= ENDPOINTS =================

// 1) Crear documento lógico
/**
 * @swagger
 * /documents:
 *   post:
 *     summary: Crear un nuevo documento lógico
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *               - created_by
 *             properties:
 *               title:
 *                 type: string
 *                 description: Título del documento
 *               created_by:
 *                 type: string
 *                 description: Creador del documento
 *     responses:
 *       201:
 *         description: Documento creado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id:
 *                   type: integer
 *                   description: ID del documento
 *                 title:
 *                   type: string
 *                   description: Título del documento
 *                 created_by:
 *                   type: string
 *                   description: Creador del documento
 *                 created_at:
 *                   type: string
 *                   format: date-time
 *                   description: Fecha de creación del documento
 */
app.post('/documents', async (req, res) => {
  try {
    const { title, created_by } = req.body;
    if (!title || !created_by) {
      return res.status(400).json({ message: 'title y created_by son requeridos' });
    }
    
    const { rows } = await pool.query(
      'INSERT INTO documents(title, created_by) VALUES($1,$2) RETURNING *',
      [title, created_by]
    );
    res.json(rows[0]);
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'Error creando documento' });
  }
});

// 2) Subir nueva versión
/**
 * @swagger
 * /documents/{id}/upload:
 *   post:
 *     summary: Subir una nueva versión de un documento
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *           description: ID del documento
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required:
 *               - file
 *             properties:
 *               file:
 *                 type: string
 *                 format: binary
 *                 description: Archivo a subir
 *     responses:
 *       201:
 *         description: Versión subida exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id:
 *                   type: integer
 *                   description: ID de la versión
 *                 document_id:
 *                   type: integer
 *                   description: ID del documento
 *                 version:
 *                   type: integer
 *                   description: Número de versión
 *                 original_filename:
 *                   type: string
 *                   description: Nombre original del archivo
 *                 storage_path:
 *                   type: string
 *                   description: Ruta de almacenamiento del archivo
 *                 mime_type:
 *                   type: string
 *                   description: Tipo MIME del archivo
 *                 size_bytes:
 *                   type: integer
 *                   description: Tamaño del archivo en bytes
 *                 created_by:
 *                   type: string
 *                   description: Creador de la versión
 *                 created_at:
 *                   type: string
 *                   format: date-time
 *                   description: Fecha de creación de la versión
 */
app.post('/documents/:id/upload', upload.single('file'), async (req, res) => {
  const client = await pool.connect();
  try {
    const documentId = parseInt(req.params.id, 10);
    if (!req.file) {
      return res.status(400).json({ message: 'Archivo requerido (file)' });
    }

    const { originalname, path: storagePath, mimetype, size } = req.file;
    const version = await nextVersion(documentId);
    const created_by = req.body?.created_by || 'system';

    await client.query('BEGIN');
    const insert = `
      INSERT INTO document_versions(document_id, version, original_filename, storage_path, mime_type, size_bytes, created_by)
      VALUES ($1,$2,$3,$4,$5,$6,$7)
      RETURNING *`;
    const { rows } = await client.query(insert, [
      documentId, version, originalname, storagePath, mimetype, size, created_by
    ]);
    await client.query('COMMIT');

    res.json(rows[0]);
  } catch (e) {
    await client.query('ROLLBACK');
    console.error(e);
    res.status(500).json({ message: 'Error subiendo versión' });
  } finally {
    client.release();
  }
});

// 3) Listar versiones de un documento
/**
 * @swagger
 * /documents/{id}/versions:
 *   get:
 *     summary: Listar versiones de un documento
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *           description: ID del documento
 *     responses:
 *       200:
 *         description: Versiones del documento
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/DocumentVersion'
 */
app.get('/documents/:id/versions', async (req, res) => {
  try {
    const documentId = parseInt(req.params.id, 10);
    const { rows } = await pool.query(
      'SELECT * FROM document_versions WHERE document_id=$1 ORDER BY version DESC',
      [documentId]
    );
    res.json(rows);
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'Error listando versiones' });
  }
});

// 4) Listar todos los documentos
/**
 * @swagger
 * /documents:
 *   get:
 *     summary: Listar todos los documentos
 *     responses:
 *       200:
 *         description: Documentos
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Document'
 */
app.get('/documents', async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT * FROM documents ORDER BY created_at DESC'
    );
    res.json(rows);
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'Error listando documentos' });
  }
});

// 5) Firmar documento (genera PDF firmado)
/**
 * @swagger
 * /documents/{id}/versions/{version}/sign:
 *   post:
 *     summary: Firmar un documento
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *           description: ID del documento
 *       - in: path
 *         name: version
 *         required: true
 *         schema:
 *           type: integer
 *           description: Número de versión
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - signer
 *             properties:
 *               signer:
 *                 type: string
 *                 description: Firmante del documento
 *     responses:
 *       200:
 *         description: Documento firmado
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   description: Mensaje de éxito
 *                 signed_pdf_path:
 *                   type: string
 *                   description: Ruta del PDF firmado
 */
app.post('/documents/:id/versions/:version/sign', async (req, res) => {
  const client = await pool.connect();
  try {
    const documentId = parseInt(req.params.id, 10);
    const version = parseInt(req.params.version, 10);
    const signer = req.body?.signer || 'Usuario';

    const { rows } = await pool.query(
      'SELECT * FROM document_versions WHERE document_id=$1 AND version=$2',
      [documentId, version]
    );
    if (rows.length === 0) {
      return res.status(404).json({ message: 'Versión no encontrada' });
    }

    const v = rows[0];
    const ext = path.extname(v.storage_path).toLowerCase();
    let pdfToSignPath;

    // Si ya es PDF, firmamos directo. Si es DOCX, convertimos.
    if (ext === '.pdf') {
      pdfToSignPath = v.storage_path;
    } else if (ext === '.docx') {
      const outPdf = changeExtToPdf(v.storage_path, UPLOAD_DIR);
      await docxToPdf(v.storage_path, outPdf);
      pdfToSignPath = outPdf;
    } else {
      return res.status(400).json({ 
        message: `Formato no soportado para firmar: ${ext}` 
      });
    }

    // Firmar (agregar pie)
    const signedOut = path.join(SIGNED_DIR, `${path.basename(pdfToSignPath, '.pdf')}.signed.pdf`);
    await signPdfFooter(pdfToSignPath, signedOut, signer, new Date());

    // Guardar referencia en BD
    await client.query('BEGIN');
    await client.query(
      'UPDATE document_versions SET is_signed=true, signed_pdf_path=$1 WHERE id=$2',
      [signedOut, v.id]
    );
    await client.query('COMMIT');

    res.json({ 
      message: 'Documento firmado exitosamente', 
      signed_pdf_path: signedOut 
    });
  } catch (e) {
    await client.query('ROLLBACK');
    console.error(e);
    res.status(500).json({ message: 'Error firmando PDF' });
  } finally {
    client.release();
  }
});

// 6) Descargar archivo (original o firmado)
/**
 * @swagger
 * /download:
 *   get:
 *     summary: Descargar un archivo
 *     parameters:
 *       - in: query
 *         name: path
 *         required: true
 *         schema:
 *           type: string
 *           description: Ruta del archivo a descargar
 *     responses:
 *       200:
 *         description: Archivo descargado
 *         content:
 *           application/octet-stream:
 *             schema:
 *               type: string
 *               format: binary
 */
app.get('/download', async (req, res) => {
  try {
    const filePath = req.query.path;
    if (!filePath) {
      return res.status(400).json({ message: 'Debe indicar ?path=' });
    }
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ message: 'Archivo no encontrado' });
    }
    res.download(filePath);
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'Error descargando archivo' });
  }
});

// 7) Endpoint de salud
/**
 * @swagger
 * /health:
 *   get:
 *     summary: Verificar salud del servidor
 *     responses:
 *       200:
 *         description: Servidor en funcionamiento
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   description: Estado del servidor
 *                 service:
 *                   type: string
 *                   description: Nombre del servicio
 *                 timestamp:
 *                   type: string
 *                   format: date-time
 *                   description: Fecha y hora actual
 */
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    service: 'Sistema de Gestión Documental',
    timestamp: new Date().toISOString()
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Sistema de Gestión Documental ejecutándose en puerto ${PORT}`);
  console.log(`📁 Directorio de uploads: ${UPLOAD_DIR}`);
  console.log(`✍️  Directorio de firmados: ${SIGNED_DIR}`);
});
