// Script de prueba para verificar dependencias
console.log('🔍 Verificando dependencias...');

try {
  const express = require('express');
  console.log('✅ Express: OK');
  
  const cors = require('cors');
  console.log('✅ CORS: OK');
  
  const joi = require('joi');
  console.log('✅ Joi: OK');
  
  const multer = require('multer');
  console.log('✅ Multer: OK');
  
  const swaggerJsdoc = require('swagger-jsdoc');
  console.log('✅ Swagger JSDoc: OK');
  
  const swaggerUi = require('swagger-ui-express');
  console.log('✅ Swagger UI: OK');
  
  require('dotenv').config();
  console.log('✅ DotEnv: OK');
  
  console.log('\n🚀 Todas las dependencias están disponibles');
  console.log('📋 Variables de entorno:');
  console.log('   - PORT:', process.env.PORT || '3001 (default)');
  console.log('   - DB_HOST:', process.env.DB_HOST || 'No configurado');
  console.log('   - NODE_ENV:', process.env.NODE_ENV || 'No configurado');
  
  // Crear servidor de prueba simple
  const app = express();
  const PORT = process.env.PORT || 3001;
  
  app.get('/', (req, res) => {
    res.json({
      message: 'Servidor de prueba funcionando',
      timestamp: new Date().toISOString(),
      port: PORT
    });
  });
  
  app.listen(PORT, () => {
    console.log(`\n🎉 Servidor de prueba iniciado exitosamente en puerto ${PORT}`);
    console.log(`🌐 Accede a: http://localhost:${PORT}`);
    console.log('\n⚠️  Para detener: Ctrl+C');
  });
  
} catch (error) {
  console.error('❌ Error al cargar dependencias:', error.message);
  console.error('💡 Ejecuta: npm install');
  process.exit(1);
}
