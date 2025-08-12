# Dosimatic - Document Management System

Sistema completo de gestión documental con backend Node.js/Express y frontend Flutter.

## Estructura del Proyecto

```
dosimatic/
├── backend/          # API REST con Node.js + Express + PostgreSQL
├── sewin/           # Frontend Flutter Web
└── README.md
```

## Backend (Node.js/Express)

### Características
- API REST completa para gestión de documentos
- Base de datos PostgreSQL
- Sistema de versionado de documentos
- Workflow de aprobación
- Subida de archivos con validación
- Documentación Swagger
- Middleware de autenticación y validación

### Tecnologías
- Node.js + Express
- PostgreSQL
- Multer (subida de archivos)
- Joi (validación)
- Swagger (documentación)

## Frontend (Flutter Web)

### Características
- Interfaz web moderna y responsiva
- Gestión completa de documentos
- Visualización de estados y workflow
- Integración con API backend

### Tecnologías
- Flutter Web
- Dart
- Material Design

## Configuración y Ejecución

### Backend
```bash
cd backend
npm install
npm start
```

### Frontend
```bash
cd sewin
flutter pub get
flutter run -d web
```

## Docker

El proyecto incluye configuración Docker para despliegue completo:
- PostgreSQL database
- Backend API
- Frontend web

## API Documentation

Una vez ejecutado el backend, la documentación Swagger está disponible en:
`http://localhost:3500/`

## Contribución

1. Fork el proyecto
2. Crea una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Abre un Pull Request
