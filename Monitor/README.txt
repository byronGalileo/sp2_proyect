# service-monitor

Monitor configurable de servicios `systemd` (local o por SSH) con intento de recuperación (start/restart) y logging rotativo.

## Archivos
- `monitor.py`: programa principal
- `config.sample.json`: ejemplo de configuración
- `svcctl-monitor.service`: unit opcional de systemd para correr en 2° plano

## Requisitos
- Python 3.8+
- Acceso a `systemctl` local y/o remoto por SSH (con claves sin password)
- Permiso `sudo` para `systemctl start|restart` según corresponda

## Uso rápido
1. Copia y edita `config.sample.json`:
```
cp config.sample.json config.json
nano config.json
```
2. Ejecuta una sola vez para probar:
```
python3 monitor.py --config config.json --once
```
3. Ejecuta en bucle:
```
python3 monitor.py --config config.json
```

### Estructura `config.json`
```json
{
  "log_file": "logs/service_monitor.log",
  "log_level": "INFO",
  "interval_sec": 30,
  "targets": [
    {
      "name": "local-nginx",
      "method": "local",
      "service": "nginx.service",
      "recover_on_down": true,
      "recover_action": "start",
      "timeout_sec": 20
    },
    {
      "name": "remote-prometheus",
      "method": "ssh",
      "host": "10.10.0.15",
      "service": "prometheus.service",
      "ssh": {"user": "svcctl", "port": 22},
      "recover_on_down": true,
      "recover_action": "restart",
      "timeout_sec": 20
    }
  ]
}
```
- `method`: `local` o `ssh`
- `recover_action`: `start` o `restart`
- Para `ssh`, asegúrate de que el usuario remoto tenga `sudo` sin contraseña **sólo** para `systemctl start|restart` del servicio permitido (usa una lista blanca).

## systemd unit (opcional)
Instala `svcctl-monitor.service` en `/etc/systemd/system/` y habilita:
```
sudo cp svcctl-monitor.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now svcctl-monitor
```
Ajusta las rutas dentro del unit según dónde ubiques el proyecto.

## Seguridad y escalabilidad
- **Lista blanca + sudoers**: limita `systemctl` a servicios concretos mediante un wrapper como `safe-systemctl` y `sudoers` con NOPASSWD.
- **SSH con claves** y restricción de IPs (firewall / Security Groups).
- **Logs rotativos**: archivo rota a 2MB x 5 backups.
- **Múltiples targets**: añade tantos servicios/hosts como necesites en `targets`.
- **Integración futura**: expón métricas Prometheus leyendo el log o añadiendo un endpoint HTTP simple.
