#!/bin/bash
# ============================================================
# Service Monitor v2.0 - BeagleBone Compatible Wrapper Script
# ------------------------------------------------------------
# Ejecuta el monitor directamente con el Python global del sistema.
# Este script elimina la dependencia del entorno virtual (venv).
# ============================================================

# Directorio donde se encuentra este script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PYTHON_BIN="/usr/bin/python3"
MONITOR_SCRIPT="$SCRIPT_DIR/monitor.py"
LOG_DIR="$PROJECT_ROOT/logs"
CONFIG_FILE="$1"

# Asegurarse de que los argumentos sean válidos
if [ -z "$CONFIG_FILE" ]; then
    echo "❌ Missing configuration file argument"
    echo "Usage: $0 --config <config_path>"
    exit 1
fi

# Crear carpeta de logs si no existe
mkdir -p "$LOG_DIR"

# Mostrar información de contexto
echo "🚀 Starting Service Monitor v2.0 (No VENV)"
echo "📁 Project root: $PROJECT_ROOT"
echo "🐍 Python executable: $PYTHON_BIN"
echo "⚙️ Config file: $CONFIG_FILE"
echo "📝 Logs: $LOG_DIR"

# Cambiar al directorio del monitor
cd "$SCRIPT_DIR" || exit 1

# Ejecutar el monitor directamente con Python global
$PYTHON_BIN "$MONITOR_SCRIPT" "$@" \
  >> "$LOG_DIR/monitor_stdout.log" \
  2>> "$LOG_DIR/monitor_stderr.log"

# Capturar código de salida
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo "❌ Monitor exited with code $EXIT_CODE (check logs in $LOG_DIR)"
else
    echo "✅ Monitor completed successfully"
fi

exit $EXIT_CODE
