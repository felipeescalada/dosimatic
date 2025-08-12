const Documento = require('../models/documento');
const Joi = require('joi');
const path = require('path');
const fs = require('fs').promises;

// Esquema de validación para crear documento
const createDocumentoSchema = Joi.object({
  codigo: Joi.string().required().max(50),
  nombre: Joi.string().required().max(255),
  descripcion: Joi.string().optional(),
  gestion_id: Joi.number().integer().positive().required(),
  convencion: Joi.string().valid('Manual', 'Procedimiento', 'Instructivo', 'Formato', 'Documento Externo').required(),
  vinculado_a: Joi.number().integer().positive().optional(),
  usuario_creador: Joi.number().integer().positive().required()
});

// Esquema de validación para actualizar documento
const updateDocumentoSchema = Joi.object({
  nombre: Joi.string().max(255).optional(),
  descripcion: Joi.string().optional(),
  gestion_id: Joi.number().integer().positive().optional(),
  convencion: Joi.string().valid('Manual', 'Procedimiento', 'Instructivo', 'Formato', 'Documento Externo').optional(),
  vinculado_a: Joi.number().integer().positive().optional(),
  estado: Joi.string().valid('pendiente_revision', 'pendiente_aprobacion', 'aprobado', 'rechazado').optional(),
  usuario_revisor: Joi.number().integer().positive().optional(),
  usuario_aprobador: Joi.number().integer().positive().optional(),
  comentarios_revision: Joi.string().optional(),
  comentarios_aprobacion: Joi.string().optional()
});

class DocumentoController {
  // Crear nuevo documento
  static async create(req, res) {
    try {
      // Validar datos de entrada
      const { error, value } = createDocumentoSchema.validate(req.body);
      if (error) {
        return res.status(400).json({
          success: false,
          message: 'Datos inválidos',
          errors: error.details.map(detail => detail.message)
        });
      }

      // Procesar archivos subidos
      const documentoData = { ...value };
      
      if (req.files) {
        if (req.files.archivo_fuente) {
          documentoData.archivo_fuente = req.files.archivo_fuente[0].filename;
        }
        if (req.files.archivo_pdf) {
          documentoData.archivo_pdf = req.files.archivo_pdf[0].filename;
        }
      }

      // Crear documento
      const documento = await Documento.create(documentoData);

      res.status(201).json({
        success: true,
        message: 'Documento creado exitosamente',
        data: documento
      });

    } catch (error) {
      console.error('Error creando documento:', error);
      
      // Limpiar archivos subidos si hay error
      if (req.files) {
        try {
          for (const file of Object.values(req.files).flat()) {
            await fs.unlink(file.path);
          }
        } catch (cleanupError) {
          console.error('Error limpiando archivos:', cleanupError);
        }
      }

      if (error.code === '23505') { // Código único violado
        return res.status(400).json({
          success: false,
          message: 'El código del documento ya existe'
        });
      }

      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  }

  // Obtener todos los documentos con filtros
  static async getAll(req, res) {
    try {
      const filters = {
        codigo: req.query.codigo,
        nombre: req.query.nombre,
        gestion_id: req.query.gestion_id ? parseInt(req.query.gestion_id) : undefined,
        convencion: req.query.convencion,
        estado: req.query.estado,
        limit: req.query.limit ? parseInt(req.query.limit) : 50,
        offset: req.query.offset ? parseInt(req.query.offset) : 0
      };

      // Remover valores undefined
      Object.keys(filters).forEach(key => {
        if (filters[key] === undefined) {
          delete filters[key];
        }
      });

      const documentos = await Documento.findAll(filters);

      res.json({
        success: true,
        data: documentos,
        pagination: {
          limit: filters.limit,
          offset: filters.offset,
          total: documentos.length
        }
      });

    } catch (error) {
      console.error('Error obteniendo documentos:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  }

  // Obtener documento por ID
  static async getById(req, res) {
    try {
      const { id } = req.params;
      
      if (!id || isNaN(parseInt(id))) {
        return res.status(400).json({
          success: false,
          message: 'ID de documento inválido'
        });
      }

      const documento = await Documento.findById(parseInt(id));

      if (!documento) {
        return res.status(404).json({
          success: false,
          message: 'Documento no encontrado'
        });
      }

      res.json({
        success: true,
        data: documento
      });

    } catch (error) {
      console.error('Error obteniendo documento:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  }

  // Actualizar documento
  static async update(req, res) {
    try {
      const { id } = req.params;
      const usuarioId = req.body.usuario_id || req.user?.id;

      if (!id || isNaN(parseInt(id))) {
        return res.status(400).json({
          success: false,
          message: 'ID de documento inválido'
        });
      }

      // Validar datos de entrada
      const { error, value } = updateDocumentoSchema.validate(req.body);
      if (error) {
        return res.status(400).json({
          success: false,
          message: 'Datos inválidos',
          errors: error.details.map(detail => detail.message)
        });
      }

      // Procesar archivos subidos
      const updateData = { ...value };
      
      if (req.files) {
        if (req.files.archivo_fuente) {
          updateData.archivo_fuente = req.files.archivo_fuente[0].filename;
        }
        if (req.files.archivo_pdf) {
          updateData.archivo_pdf = req.files.archivo_pdf[0].filename;
        }
      }

      // Actualizar documento
      const documento = await Documento.update(parseInt(id), updateData, usuarioId);

      res.json({
        success: true,
        message: 'Documento actualizado exitosamente',
        data: documento
      });

    } catch (error) {
      console.error('Error actualizando documento:', error);
      
      // Limpiar archivos subidos si hay error
      if (req.files) {
        await this.cleanupUploadedFiles(req.files);
      }

      if (error.message === 'Documento no encontrado') {
        return res.status(404).json({
          success: false,
          message: error.message
        });
      }

      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  }

  // Eliminar documento
  static async delete(req, res) {
    try {
      const { id } = req.params;

      if (!id || isNaN(parseInt(id))) {
        return res.status(400).json({
          success: false,
          message: 'ID de documento inválido'
        });
      }

      const deleted = await Documento.delete(parseInt(id));

      if (!deleted) {
        return res.status(404).json({
          success: false,
          message: 'Documento no encontrado'
        });
      }

      res.json({
        success: true,
        message: 'Documento eliminado exitosamente'
      });

    } catch (error) {
      console.error('Error eliminando documento:', error);
      
      if (error.message.includes('documentos vinculados')) {
        return res.status(400).json({
          success: false,
          message: error.message
        });
      }

      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  }

  // Obtener histórico de versiones
  static async getHistorico(req, res) {
    try {
      const { id } = req.params;

      if (!id || isNaN(parseInt(id))) {
        return res.status(400).json({
          success: false,
          message: 'ID de documento inválido'
        });
      }

      const historico = await Documento.getHistorico(parseInt(id));

      res.json({
        success: true,
        data: historico
      });

    } catch (error) {
      console.error('Error obteniendo histórico:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  }

  // Marcar como revisado
  static async marcarRevisado(req, res) {
    try {
      const { id } = req.params;
      const { usuario_revisor, comentarios } = req.body;

      if (!id || isNaN(parseInt(id))) {
        return res.status(400).json({
          success: false,
          message: 'ID de documento inválido'
        });
      }

      if (!usuario_revisor) {
        return res.status(400).json({
          success: false,
          message: 'Usuario revisor es requerido'
        });
      }

      const documento = await Documento.marcarRevisado(
        parseInt(id), 
        usuario_revisor, 
        comentarios
      );

      res.json({
        success: true,
        message: 'Documento marcado como revisado',
        data: documento
      });

    } catch (error) {
      console.error('Error marcando como revisado:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  }

  // Marcar como aprobado
  static async marcarAprobado(req, res) {
    try {
      const { id } = req.params;
      const { usuario_aprobador, comentarios } = req.body;

      if (!id || isNaN(parseInt(id))) {
        return res.status(400).json({
          success: false,
          message: 'ID de documento inválido'
        });
      }

      if (!usuario_aprobador) {
        return res.status(400).json({
          success: false,
          message: 'Usuario aprobador es requerido'
        });
      }

      const documento = await Documento.marcarAprobado(
        parseInt(id), 
        usuario_aprobador, 
        comentarios
      );

      res.json({
        success: true,
        message: 'Documento aprobado exitosamente',
        data: documento
      });

    } catch (error) {
      console.error('Error aprobando documento:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  }

  // Rechazar documento
  static async rechazar(req, res) {
    try {
      const { id } = req.params;
      const { usuario_id, comentarios } = req.body;

      if (!id || isNaN(parseInt(id))) {
        return res.status(400).json({
          success: false,
          message: 'ID de documento inválido'
        });
      }

      if (!usuario_id) {
        return res.status(400).json({
          success: false,
          message: 'Usuario es requerido'
        });
      }

      const documento = await Documento.rechazar(
        parseInt(id), 
        usuario_id, 
        comentarios
      );

      res.json({
        success: true,
        message: 'Documento rechazado',
        data: documento
      });

    } catch (error) {
      console.error('Error rechazando documento:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  }

  // Obtener documentos pendientes de revisión
  static async getPendientesRevision(req, res) {
    try {
      const documentos = await Documento.getPendientesRevision();

      res.json({
        success: true,
        data: documentos
      });

    } catch (error) {
      console.error('Error obteniendo pendientes de revisión:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  }

  // Obtener documentos pendientes de aprobación
  static async getPendientesAprobacion(req, res) {
    try {
      const documentos = await Documento.getPendientesAprobacion();

      res.json({
        success: true,
        data: documentos
      });

    } catch (error) {
      console.error('Error obteniendo pendientes de aprobación:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  }

  // Descargar archivo
  static async downloadFile(req, res) {
    try {
      const { id, tipo } = req.params; // tipo: 'fuente' o 'pdf'

      if (!id || isNaN(parseInt(id))) {
        return res.status(400).json({
          success: false,
          message: 'ID de documento inválido'
        });
      }

      const documento = await Documento.findById(parseInt(id));

      if (!documento) {
        return res.status(404).json({
          success: false,
          message: 'Documento no encontrado'
        });
      }

      const fileName = tipo === 'fuente' ? documento.archivo_fuente : documento.archivo_pdf;

      if (!fileName) {
        return res.status(404).json({
          success: false,
          message: `Archivo ${tipo} no encontrado`
        });
      }

      const filePath = path.join(process.env.UPLOADS_PATH || 'uploads', fileName);

      try {
        await fs.access(filePath);
        res.download(filePath, fileName);
      } catch (error) {
        res.status(404).json({
          success: false,
          message: 'Archivo no encontrado en el servidor'
        });
      }

    } catch (error) {
      console.error('Error descargando archivo:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  }

  // Método auxiliar para limpiar archivos subidos en caso de error
  static async cleanupUploadedFiles(files) {
    try {
      const allFiles = Object.values(files).flat();
      for (const file of allFiles) {
        await fs.unlink(file.path);
      }
    } catch (error) {
      console.error('Error limpiando archivos:', error);
    }
  }
}

module.exports = DocumentoController;
