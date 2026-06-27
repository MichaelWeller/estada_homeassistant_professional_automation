#!/usr/bin/with-contenv bashio

export NODE_ENV=production
export HA_URL="http://supervisor/core"
export RULES_PATH="$(bashio::config 'rules_path')"
export LOG_LEVEL="$(bashio::config 'log_level')"

node /app/dist/index.js
