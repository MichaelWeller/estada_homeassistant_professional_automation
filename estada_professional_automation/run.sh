#!/usr/bin/with-contenv bashio

set -Eeuo pipefail

export NODE_ENV=production
export HA_URL="http://supervisor/core"
export RULES_PATH="$(bashio::config 'rules_path')"
export LOG_LEVEL="$(bashio::config 'log_level')"

echo "[INFO] Estada Professional Automation starting"
echo "[INFO] rules_path=${RULES_PATH} log_level=${LOG_LEVEL}"

if [ ! -f /app/dist/index.js ]; then
	echo "[ERROR] Missing /app/dist/index.js. Build step likely failed during image creation."
	exit 1
fi

exec node /app/dist/index.js
