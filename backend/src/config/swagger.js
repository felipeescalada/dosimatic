const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'SecWin API Documentation',
      version: '1.0.0',
      description: 'API documentation for SecWin system including user authentication and contact management',
    },
    servers: [
      {
        url: 'http://localhost:3500',
        description: 'Development server',
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
  apis: [__dirname + '/../routes/*.js'], // Path to the API routes
};

module.exports = swaggerJsdoc(options);
