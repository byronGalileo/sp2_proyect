
Port Health Check - Quick Start
--------------------------------

Descripción:
Herramienta simple en Python para revisar puertos locales y, opcionalmente, hacer GET HTTP en 80/443. 
Imprime en consola y puede guardar JSON/CSV para análisis.

Requisitos:
- Python 3.8+

Uso básico:
1) Ejecutar una sola vez sobre localhost en puertos 22,80,443:
   python3 port_health_check.py --host 127.0.0.1 --ports 22,80,443 --http

2) Observar continuamente cada 10 segundos y guardar CSV:
   python3 port_health_check.py --host 127.0.0.1 --ports 22-25,80,443 --http --watch 10 --csv-out health.csv

3) Cambiar el path HTTP para health checks específicos:
   python3 port_health_check.py --host 127.0.0.1 --ports 80,443 --http --http-path /healthz

Campos de salida:
- timestamp, host, port, tcp_ok, tcp_latency_ms, error, http_status, http_latency_ms

Buenas prácticas y consideraciones:
- Usar timeouts bajos para no bloquear el ciclo de chequeo.
- Si un puerto debe estar cerrado por seguridad, verifiquen que aparezca como CLOSED.
- Para chequear servicios con login o payload específico, extender a un módulo de autenticación.
- Integración futura: enviar estos resultados a la API en la nube del proyecto.
