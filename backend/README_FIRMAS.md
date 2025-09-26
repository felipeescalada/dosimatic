# Sistema de Firmas Digitales

## Configuración de Imágenes de Firma

### 1. Estructura de Directorios
```
backend/
├── signatures/
│   ├── default_signature.png     # Firma por defecto del sistema
│   ├── user_1_signature.png      # Firma del usuario ID 1
│   ├── user_2_signature.png      # Firma del usuario ID 2
│   └── ...
├── signed/                       # Documentos firmados
└── uploads/                      # Documentos originales
```

### 2. Tipos de Firmas

#### **Firma por Defecto del Sistema**
- Archivo: `signatures/default_signature.png`
- Se usa cuando no se especifica `usuario_firmante`
- Configurable en `.env` con `DEFAULT_SIGNATURE`

#### **Firmas de Usuarios Registrados**
- Archivo: `signatures/user_{id}_signature.png`
- Se usa cuando se especifica `usuario_firmante` en el request
- Los usuarios suben sus firmas via `/api/users/{id}/signature`

### 3. Configuración en .env
```bash
# Directorio donde se almacenan las firmas
SIGNATURES_PATH=./signatures

# Firma por defecto del sistema
DEFAULT_SIGNATURE=signatures/default_signature.png
```

### 4. Cómo Usar

#### **Firmar con firma por defecto:**
```json
POST /api/documentos/{id}/firmar
{
  "signer_name": "Juan Pérez"
}
```

#### **Firmar con firma específica de usuario:**
```json
POST /api/documentos/{id}/firmar
{
  "signer_name": "Juan Pérez",
  "usuario_firmante": 123
}
```

### 5. Subir Firma de Usuario
```bash
POST /api/users/{id}/signature
Content-Type: multipart/form-data

signature: [archivo PNG/JPG]
```

### 6. Formatos Soportados
- **Documentos:** .docx, .doc, .xlsx, .xls
- **Firmas:** .png, .jpg, .jpeg
- **Tamaño máximo:** 5MB

### 7. Crear Firma por Defecto

Para crear una firma por defecto, puedes:

1. **Usar una imagen existente:**
   - Copia tu imagen de firma a `signatures/default_signature.png`

2. **Crear una imagen simple con texto:**
   - Tamaño recomendado: 300x150 pixels
   - Fondo transparente (PNG)
   - Texto: "FIRMA DIGITAL" o el nombre de tu empresa

3. **Usar herramientas online:**
   - Signature Maker
   - Canva
   - GIMP/Photoshop

### 8. Ejemplo de Uso Completo

```javascript
// 1. Usuario sube su firma
POST /api/users/123/signature
// Archivo: user_123_signature.png

// 2. Firmar documento con firma del usuario
POST /api/documentos/456/firmar
{
  "signer_name": "María García",
  "usuario_firmante": 123
}

// 3. El sistema usa: signatures/user_123_signature.png
```

### 9. Troubleshooting

#### **Error: "Imagen de firma no encontrada"**
- Verificar que existe `signatures/default_signature.png`
- O que el usuario tiene firma registrada
- Verificar permisos de lectura en el directorio

#### **Error: "No se pudo leer el archivo Excel"**
- Verificar que el archivo no esté corrupto
- Verificar que ExcelJS está instalado: `npm install exceljs`

#### **Error: "Script Python no encontrado"**
- Instalar dependencias: `pip install -r requirements.txt`
- Verificar que Python3 está disponible en PATH
