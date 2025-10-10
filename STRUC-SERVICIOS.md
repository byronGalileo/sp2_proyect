## Servicios Beagle: 
- Codigo que hara los check a los servicios configurados 
    - MYSQL 
    - APACHE 
    - HTTP 
    - ETC 
- Servicio que exponga los logs de los checks (Mongo - Automatico) 
- Servicio que levante un proceso para los check ports (Manual) 
    - NMAP 
    - PUERTOS ABIERTOS 
- Servicio que genera un config JSON 
    - Lee de mongo y genera un JSON independiente 
- Serivicios API MONGO 
    - Servicio para agregar un nuevo servicio 
    - Servicio para crear la configuracion de un nuevo servicio
    - Servicio para almacenar los logs
- Endpoint to start, restart, stop 

## Servicios API BACKEND 
Servicios que va a consumir el FRONT 
- Administracion de usuarios - (MYSQL) 
    - Authentica - ya 
    - Registra - ya 
    - Gestion de Permisos - pendiente 
- Gestion de monitoreos 
    - Endpoint para agregar nuevo servicio 
    - Endpoint para vista general de status de servicios 
    - Endpoint para recivir informacion de los logs 
    - Endpoint para generar un check ports 
    - Endpoint para enviar check status a la IA 

## Vistas Front 
- Authenticacion - medio terminado 
- Registro - medio terminado 
- Perfil de usuario - pendiente 
    - Actualizacion de usuarios 
- Gestion de usuarios - pendiente 
- Home - pendiente 
    - Cards de resumen, con servicios, En linea, Alertas 
    - Lista de Host 
- Vista de servicios de host 
    - Lista de servicios de host configurados 
        - Agregar, eliminar, actualizar servicios 
        - Opcion para genera port check 
- Vista detallada del estado de todos los hosts - Prioridad 1 
- Vista para de port check 
- Vista de Logs detallada de cada host -> Servicio 
    - Envio de info a IA 
    - Vista de resultados de IA 