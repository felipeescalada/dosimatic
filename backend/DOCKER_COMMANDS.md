# Comandos Docker y Documentación

## Comandos Básicos de Docker

### Iniciar y detener contenedores
```bash
# Iniciar todos los servicios en segundo plano
docker-compose up -d

# Detener y eliminar contenedores
docker-compose down

# Reconstruir y reiniciar
docker-compose up -d --build

# Ver logs en tiempo real
docker-compose logs -f

# Acceder al contenedor del backend
docker-compose exec backend bash
```

### Gestión de volúmenes
```bash
# Listar volúmenes
docker volume ls

# Inspeccionar un volumen
docker volume inspect nombre_volumen

# Eliminar volúmenes no utilizados
docker volume prune
```

## Script de Firma Digital

### Ubicación
- **Contenedor**: `/app/scripts/firmar_word.py`
- **Host local**: `./scripts/firmar_word.py`

### Uso Básico
```bash
# Dentro del contenedor
python3 /app/scripts/firmar_word.py \
  /ruta/entrada.docx \
  --firma1 /ruta/firma1.png \
  --firma2 /ruta/firma2.png \
  --firma3 /ruta/firma3.png \
  --salida /ruta/salida.docx \
  --firmante "Nombre del Firmante"
```

### Parámetros
| Parámetro | Requerido | Descripción |
|-----------|-----------|-------------|
| `archivo_entrada` | Sí | Ruta al documento Word de entrada |
| `--firma1` | Sí | Ruta a la primera imagen de firma |
| `--firma2` | No | Ruta a la segunda imagen de firma |
| `--firma3` | No | Ruta a la tercera imagen de firma |
| `--salida` | No | Ruta de salida (por defecto: [nombre_original]_firmado.docx) |
| `--firmante` | No | Nombre del firmante |

## Base de Datos

### Comandos Útiles
```bash
# Ejecutar script SQL
docker-compose exec -T db psql -U postgres -d secwin_db < archivo.sql

# Crear backup
docker-compose exec -T db pg_dump -U postgres secwin_db > backup_$(date +%Y%m%d).sql

# Restaurar backup
cat backup_file.sql | docker-compose exec -T db psql -U postgres -d secwin_db

# Acceder a la consola de PostgreSQL
docker-compose exec db psql -U postgres -d secwin_db
```

## Mantenimiento

### Limpieza
```bash
# Detener y eliminar todos los contenedores
docker-compose down

# Eliminar volúmenes no utilizados
docker volume prune

# Eliminar imágenes no utilizadas
docker image prune -a

# Limpieza completa (cuidado)
docker system prune -a
```

### Monitoreo
```bash
# Ver uso de recursos
docker stats

# Ver procesos en ejecución
docker ps

# Ver todos los contenedores (incluyendo detenidos)
docker ps -a
```

## Solución de Problemas

### Reconstruir contenedor específico
```bash
docker-compose up -d --no-deps --build nombre_servicio
```

### Ver logs de un servicio
```bash
docker-compose logs -f nombre_servicio
```

### Ejecutar comando en contenedor
```bash
docker-compose exec nombre_servicio comando
```

### Copiar archivos desde/hacia contenedor
```bash
# Desde host a contenedor
docker cp archivo_local nombre_contenedor:/ruta/destino/

# Desde contenedor a host
docker cp nombre_contenedor:/ruta/origen/archivo archivo_local
```
docker-compose cp scripts/firmar_word.py backend:/app/scripts/firmar_word.py
docker-compose restart backend