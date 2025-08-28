const express = require('express');
const cors = require('cors');
const path = require('path');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
require('dotenv').config();

const { testConnection } = require('./config/database');
const documentosRoutes = require('./routes/documentos');
const usersRoutes = require('./routes/users');
const authRoutes = require('./routes/auth.routes');
const contactRoutes = require('./routes/contact.routes');

const app = express();

// Configuración de CORS
const allowedOrigins = [
  'http://localhost:3000',  // Flutter web default port
  'http://localhost:3001',  // Common development port
  'http://localhost:3500',  // Your API port
  'http://127.0.0.1:3000',  // Alternative localhost
  'http://127.0.0.1:3001',
  'http://127.0.0.1:3500'
];

const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    if (allowedOrigins.includes(origin) || 
        process.env.NODE_ENV !== 'production') {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  optionsSuccessStatus: 200
};

// Aplicar CORS
app.use(cors(corsOptions));
app.options('*', cors(corsOptions)); // Habilitar preflight para todas las rutas

// Middleware global
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Servir archivos estáticos (uploads)
const uploadsPath = process.env.UPLOADS_PATH || 'uploads';
app.use('/uploads', express.static(path.join(__dirname, '..', uploadsPath)));

// Configuración de Swagger
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Sistema de Gestión Documental API',
      version: '1.0.0',
      description: 'API REST para sistema de gestión documental tipo Documatic',
      contact: {
        name: 'Equipo de Desarrollo',
        email: 'desarrollo@empresa.com'
      }
    },
    servers: [
      {
        url: `http://localhost:${process.env.PORT || 3500}`,
        description: 'Servidor de desarrollo'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT'
        }
      }
    }
  },
  apis: ['./src/routes/*.js'], // Rutas donde están las definiciones de Swagger
};

const specs = swaggerJsdoc(swaggerOptions);

// Ruta de documentación Swagger
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs, {
  explorer: true,
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'Sistema Documental API'
}));

// Ruta de salud del servidor
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Ruta de información del API
app.get('/api', (req, res) => {
  res.json({
    name: 'Sistema de Gestión Documental API',
    version: '1.0.0',
    description: 'API REST para gestión de documentos con control de versiones y flujo de aprobación',
    endpoints: {
      documentos: '/api/documentos',
      users: '/api/users',
      auth: '/api/auth',
      contacts: '/api/contacts',
      swagger: '/api-docs',
      health: '/health'
    }
  });
});

// Rutas de la API
app.use('/api/documentos', documentosRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/contacts', contactRoutes);

// Middleware de manejo de errores 404
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: `Ruta no encontrada: ${req.method} ${req.originalUrl}`,
    availableEndpoints: {
      api: '/api',
      documentos: '/api/documentos',
      users: '/api/users',
      auth: '/api/auth',
      contacts: '/api/contacts',
      swagger: '/api-docs',
      health: '/health'
    }
  });
});

// Middleware global de manejo de errores
app.use((error, req, res, next) => {
  console.error('Error no manejado:', error);
  
  // Error de validación de Joi
  if (error.isJoi) {
    return res.status(400).json({
      success: false,
      message: 'Datos de entrada inválidos',
      details: error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message
      }))
    });
  }

  // Error de base de datos
  if (error.code) {
    switch (error.code) {
      case '23505': // Violación de restricción única
        return res.status(409).json({
          success: false,
          message: 'El registro ya existe (violación de restricción única)',
          field: error.constraint
        });
      case '23503': // Violación de clave foránea
        return res.status(400).json({
          success: false,
          message: 'Referencia inválida (violación de clave foránea)',
          field: error.constraint
        });
      case '23502': // Violación de NOT NULL
        return res.status(400).json({
          success: false,
          message: 'Campo requerido faltante',
          field: error.column
        });
    }
  }

  // Error genérico
  res.status(error.status || 500).json({
    success: false,
    message: error.message || 'Error interno del servidor',
    ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
  });
});

// Función para inicializar el servidor
const initializeServer = async () => {
  try {
    // Probar conexión a la base de datos
    console.log('🔍 Probando conexión a la base de datos...');
    await testConnection();
    console.log('✅ Conexión a base de datos establecida');

    // Crear directorios necesarios si no existen
    const fs = require('fs');
    const directories = [
      path.join(__dirname, '..', uploadsPath),
      path.join(__dirname, '..', 'signed'),
      path.join(__dirname, '..', 'temp')
    ];

    directories.forEach(dir => {
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
        console.log('📁 Directorio creado:', dir);
      }
    });

    const PORT = process.env.PORT || 3500;
    
    app.listen(PORT, '0.0.0.0', () => {
      console.log('🚀 Servidor iniciado exitosamente');
      console.log(`📡 Puerto: ${PORT}`);
      console.log(`🌐 URL: http://localhost:${PORT}`);
      console.log(`📚 Documentación: http://localhost:${PORT}/api-docs`);
      console.log(`💚 Health Check: http://localhost:${PORT}/health`);
      console.log(`📋 API Info: http://localhost:${PORT}/api`);
      console.log(`🐳 Docker: ${process.env.NODE_ENV === 'production' ? 'Enabled' : 'Disabled'}`);
      console.log('─'.repeat(50));
    });

  } catch (error) {
    console.error('❌ Error al inicializar el servidor:', error.message);
    process.exit(1);
  }
};

// Manejo de cierre graceful
process.on('SIGTERM', () => {
  console.log('🛑 Recibida señal SIGTERM, cerrando servidor...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('🛑 Recibida señal SIGINT, cerrando servidor...');
  process.exit(0);
});

// Inicializar servidor
initializeServer();

module.exports = app;
