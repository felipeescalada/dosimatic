# Dosimatic - Document Management System

Sistema completo de gestión documental con backend Node.js/Express y frontend Flutter.

## Estructura del Proyecto

```
dosimatic/
├── backend/          # API REST con Node.js + Express + PostgreSQL
├── sewin/           # Frontend Flutter Web
└── README.md
```

## Configuración y Ejecución

### Prerequisites
- Node.js (v18 or higher)
- PostgreSQL (v15 or higher) 
- Flutter SDK
- Docker Desktop (optional, for containerized deployment)

### Opción 1: Desarrollo Local (Recomendado para testing)

#### 1. Configurar Base de Datos PostgreSQL Local
```bash
# Conectarse a PostgreSQL (usando psql o herramienta gráfica como DBeaver)
# Crear base de datos local
CREATE DATABASE secwin_db_local;

# Ejecutar script de configuración
psql -h localhost -U postgres -d secwin_db_local -f backend/database/setup-local-db.sql
```

**Credenciales Base de Datos Local:**
- Host: localhost
- Port: 5433
- Database: secwin_db_local
- User: postgres
- Password: password

#### 2. Configurar Backend
```bash
cd backend
npm install
cp .env.example .env.local
# Asegurarse que .env.local tenga la configuración local (ya está configurada)
npm run dev:local
```

**Backend URL:** http://localhost:3501

#### 3. Configurar Frontend Flutter
```bash
cd sewin
flutter pub get
flutter run -d web --web-port 3001
```

**Frontend URL:** http://localhost:3001

#### 4. Usuarios de Prueba
- **Admin:** admin@test.com / password
- **Usuario:** user@test.com / password  
- **Gerente:** gerente@test.com / password

### Opción 2: Docker (Producción/Contenerizado)

Para Docker, ver sección Docker abajo para instrucciones completas.

### Verificación de Configuración

#### 1. Verificar Backend
```bash
# Test API health
curl http://localhost:3501/api/auth/login

# Ver documentación Swagger
# Abrir en navegador: http://localhost:3501/
```

#### 2. Verificar Base de Datos
```bash
# Conectar a PostgreSQL y verificar tablas
psql -h localhost -p 5433 -U postgres -d secwin_db_local -c "\dt"
```

#### 3. Verificar Frontend
- Abrir http://localhost:3001 en navegador
- Iniciar sesión con usuarios de prueba
- Verificar gestión de documentos funciona

### Troubleshooting Común

#### Problema: "FATAL: password authentication failed for user secwin_user"
**Solución:** Usar configuración local (postgres/password) o verificar credenciales Docker

#### Problema: Puerto ya en uso
**Solución:** Cambiar puerto en .env.local o detener procesos en puertos 3501/3001

#### Problema: CORS errors
**Solución:** Verificar CORS_ORIGIN en .env.local incluye http://localhost:3001

## Docker

El proyecto incluye configuración Docker para despliegue completo:
- PostgreSQL database
- Backend API
- Frontend web

Para usar Docker:
```bash
cd backend
docker-compose up -d
```

### Manual Server Deployment

Para despliegue manual en servidor (reemplazar YOUR_SERVER_IP con la IP real del servidor):

#### 1. Build Backend Docker Image
```bash
cd backend
docker build -t secwin-backend:latest .
docker save secwin-backend:latest > secwin-backend.tar
```

#### 2. Build Flutter Web Application
```bash
cd sewin

# IMPORTANT: Update server IP in lib/global/global_constantes.dart
# Change: static String serverapp = 'http://YOUR_SERVER_IP:3501';
# Before building for production

flutter build web --release --base-href="/"
# Build output: sewin/build/web/
```

#### 3. Transfer Files to Server
Transfer these files to the server:
- `secwin-backend.tar`
- `sewin/build/web/` (entire directory)
- `backend/docker-compose.prod.yml`
- `backend/database/schema.sql`

#### 4. Server Setup Commands
```bash
# On server:
docker load < secwin-backend.tar

# Create directories
mkdir -p /opt/secwin/{backend,frontend,database}
mkdir -p /opt/secwin/{uploads,signed,temp,signatures}

# Copy files
cp docker-compose.prod.yml /opt/secwin/backend/
cp -r build/web /opt/secwin/frontend/
cp database/schema.sql /opt/secwin/database/

# Start services
cd /opt/secwin/backend
docker-compose -f docker-compose.prod.yml up -d
```

#### 5. Production URLs
- Frontend: http://YOUR_SERVER_IP:3002
- Backend API: http://YOUR_SERVER_IP:3501
- Database: localhost:5433

#### 6. Verification
```bash
docker-compose -f docker-compose.prod.yml ps
curl http://YOUR_SERVER_IP:3501/api/auth/login
curl http://YOUR_SERVER_IP:3002
```

## API Documentation

Una vez ejecutado el backend, la documentación Swagger está disponible en:
`http://localhost:3501/` (desarrollo local)
`http://localhost:3500/` (Docker)

## Contribución

1. Fork el proyecto
2. Crea una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Abre un Pull Request
