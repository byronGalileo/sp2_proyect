# 🌐 Service Monitor API - Documentación Completa

## ✅ API REST Implementada

Se ha creado una **API REST completa** para exponer las estadísticas de monitoreo de servicios y controlar qué logs han sido enviados al usuario.

## 🔧 Control de Logs Enviados

### Modificaciones en Base de Datos
- ✅ **Campo agregado**: `sent_to_user: boolean` en la colección `logs`
- ✅ **Índices creados**: Para consultas eficientes de logs no enviados
- ✅ **Operaciones nuevas**: `get_unsent_logs()`, `mark_logs_as_sent()`

### Estructura del Documento de Log
```json
{
  "_id": "ObjectId",
  "service_name": "dbus.service",
  "service_type": "local",
  "host": "localhost",
  "log_level": "INFO",
  "message": "[local-test] status=active active=True",
  "timestamp": "2025-09-26T07:56:30.701Z",
  "status": "active",
  "metadata": {"method": "local", "interval_sec": 10},
  "tags": ["local-test", "status_check"],
  "sent_to_user": false,  // ← NUEVO CAMPO
  "date": "2025-09-26",
  "service_key": "localhost:dbus.service"
}
```

## 🌐 Endpoints de la API

### 1. Health Check
```http
GET /health
```
**Respuesta:**
```json
{
  "status": "healthy",
  "timestamp": "2025-09-26T08:02:19.067Z",
  "database": {
    "connected": true,
    "database_name": "service_monitoring",
    "collections": {
      "logs": "logs",
      "events": "events"
    }
  }
}
```

### 2. Resumen de Servicios
```http
GET /services
```
**Respuesta:**
```json
{
  "total_services": 3,
  "services": [
    {
      "_id": "dbus.service",
      "total_logs": 9,
      "unsent_logs": 2,
      "latest_timestamp": "2025-09-26T07:56:30.701Z",
      "latest_status": "active",
      "service_type": "local",
      "host": "localhost"
    }
  ],
  "last_updated": "2025-09-26T08:02:19.067Z"
}
```

### 3. Estadísticas Generales
```http
GET /stats
```
**Respuesta:**
```json
{
  "total_services": 3,
  "total_unsent_logs": 2,
  "total_logs_24h": 15,
  "error_logs_24h": 0,
  "last_updated": "2025-09-26T08:02:19.067Z",
  "services": [...]
}
```

### 4. Estadísticas por Servicio
```http
GET /stats/{service_name}?hours=24
```
**Ejemplo:** `GET /stats/dbus.service?hours=24`
**Respuesta:**
```json
{
  "service_name": "dbus.service",
  "period_hours": 24,
  "total_logs": 9,
  "by_level": {"INFO": 9},
  "latest_activity": "2025-09-26T07:56:30.701Z"
}
```

### 5. Obtener Logs
```http
GET /logs?service_name={service}&log_level={level}&hours={hours}&limit={limit}
```
**Parámetros opcionales:**
- `service_name`: Filtrar por servicio
- `log_level`: Filtrar por nivel (INFO, WARNING, ERROR)
- `hours`: Horas hacia atrás (1-168)
- `limit`: Máximo de logs (1-1000)

**Respuesta:**
```json
{
  "total": 3,
  "logs": [
    {
      "id": "68d6472ec388de29bf1e7fbe",
      "service_name": "dbus.service",
      "log_level": "INFO",
      "message": "[local-test] status=active active=True",
      "timestamp": "2025-09-26T07:56:30.701Z",
      "sent_to_user": true,
      "metadata": {"method": "local"}
    }
  ],
  "filters": {
    "service_name": "dbus.service",
    "hours": 24,
    "limit": 3
  }
}
```

### 6. Logs No Enviados
```http
GET /logs/unsent?service_name={service}&log_level={level}&limit={limit}
```
**Respuesta:**
```json
{
  "total": 2,
  "logs": [
    {
      "id": "68d6472ec388de29bf1e7fbe",
      "service_name": "dbus.service",
      "sent_to_user": false,
      ...
    }
  ]
}
```

### 7. Marcar Logs como Enviados ⭐
```http
POST /logs/mark-sent
Content-Type: application/json

{
  "log_ids": [
    "68d6472ec388de29bf1e7fbe",
    "68d64724c388de29bf1e7fbd"
  ]
}
```
**Respuesta:**
```json
{
  "success": true,
  "message": "Marked 2 logs as sent",
  "data": {
    "requested": 2,
    "updated": 2,
    "log_ids": [
      "68d6472ec388de29bf1e7fbe",
      "68d64724c388de29bf1e7fbd"
    ]
  }
}
```

## 🚀 Cómo Ejecutar la API

### Método 1: Script Wrapper
```bash
./run_api.sh [host] [port]
# Ejemplo: ./run_api.sh 0.0.0.0 8000
```

### Método 2: Directo con Python
```bash
source venv/bin/activate
cd api/
python main.py --host 0.0.0.0 --port 8000
```

### Acceso a Documentación
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

## 🧪 Pruebas

### Prueba Completa de Funcionalidad
```bash
python3 api_final_test.py
```

### Pruebas Individuales
```bash
# Health check
curl http://localhost:8000/health

# Servicios
curl http://localhost:8000/services

# Logs no enviados
curl http://localhost:8000/logs/unsent

# Marcar como enviados
curl -X POST http://localhost:8000/logs/mark-sent \
  -H "Content-Type: application/json" \
  -d '{"log_ids": ["log_id_1", "log_id_2"]}'
```

## 📊 Resultado de Pruebas

✅ **Test realizado exitosamente:**
- **15 logs totales** en la base de datos
- **3 servicios** monitoreados (dbus.service, mysql.service, prometheus.service)
- **2 logs no enviados** inicialmente
- **Marcado exitoso** de logs como enviados
- **Verificación**: 0 logs pendientes después del marcado

## 🔗 Integración con Monitor

La API está completamente integrada con el sistema de monitoreo:

1. **Monitor genera logs** → Se guardan con `sent_to_user: false`
2. **API expone logs** → Endpoint `/logs/unsent` los entrega
3. **Cliente consume logs** → Procesa la información
4. **Cliente confirma** → Llama `/logs/mark-sent` con IDs
5. **Control completado** → Logs marcados como enviados

## 🎯 Características Clave

✅ **Control de Entrega**: Campo `sent_to_user` para tracking
✅ **API RESTful**: Endpoints estándar con documentación automática
✅ **Filtros Avanzados**: Por servicio, nivel, tiempo
✅ **Estadísticas Completas**: Resumen de servicios y métricas
✅ **Batch Operations**: Marcar múltiples logs de una vez
✅ **Error Handling**: Respuestas consistentes con códigos HTTP
✅ **CORS Support**: Configurado para acceso desde clientes web
✅ **Documentación Interactiva**: Swagger UI y ReDoc incluidos

## 🔐 Consideraciones de Producción

- **Autenticación**: Agregar según necesidades de seguridad
- **Rate Limiting**: Implementar límites de velocidad
- **HTTPS**: Configurar certificados SSL
- **Logging**: Logs estructurados de la API
- **Monitoring**: Métricas de uso de endpoints