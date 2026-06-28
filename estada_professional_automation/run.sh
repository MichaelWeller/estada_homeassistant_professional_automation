#!/usr/bin/with-contenv bashio

set -Eeuo pipefail

export NODE_ENV=production
export HA_URL="ws://supervisor/core/websocket"
export RULES_PATH="$(bashio::config 'rules_path')"
export LOG_LEVEL="$(bashio::config 'log_level')"
export ENABLE_SFTP="$(bashio::config 'enable_sftp')"
export SFTP_PORT="$(bashio::config 'sftp_port')"
export SFTP_USERNAME="$(bashio::config 'sftp_username')"
export SFTP_PASSWORD="$(bashio::config 'sftp_password')"
export ENABLE_DEBUG="$(bashio::config 'enable_debug')"
export DEBUG_PORT="$(bashio::config 'debug_port')"

mkdir -p "${RULES_PATH}"

setup_sftp() {
	if ! bashio::config.true 'enable_sftp'; then
		echo "[INFO] SFTP is disabled"
		return
	fi

	if [ -z "${SFTP_PASSWORD}" ]; then
		echo "[ERROR] SFTP is enabled, but no sftp_password is configured"
		exit 1
	fi

	if ! id -u "${SFTP_USERNAME}" >/dev/null 2>&1; then
		addgroup -S sftpusers >/dev/null 2>&1 || true
		adduser -D -S -s /sbin/nologin -G sftpusers "${SFTP_USERNAME}"
	fi

	echo "${SFTP_USERNAME}:${SFTP_PASSWORD}" | chpasswd
	ssh-keygen -A >/dev/null 2>&1

	cat > /etc/ssh/sshd_config.estada <<EOF
Port ${SFTP_PORT}
Protocol 2
PasswordAuthentication yes
PermitRootLogin no
PubkeyAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
UsePAM no
Subsystem sftp internal-sftp
AllowUsers ${SFTP_USERNAME}
PermitTTY no
AllowTcpForwarding no
X11Forwarding no
ChrootDirectory /config
ForceCommand internal-sftp -d /Estada_PA
EOF

	/usr/sbin/sshd -f /etc/ssh/sshd_config.estada
	echo "[INFO] SFTP enabled on port ${SFTP_PORT} for user ${SFTP_USERNAME}"
}

echo "[INFO] Estada Professional Automation starting"
echo "[INFO] rules_path=${RULES_PATH} log_level=${LOG_LEVEL}"

if [ ! -f /app/dist/index.js ]; then
	echo "[ERROR] Missing /app/dist/index.js. Build step likely failed during image creation."
	exit 1
fi

setup_sftp

NODE_ARGS="--enable-source-maps"
if bashio::config.true 'enable_debug'; then
	NODE_ARGS="${NODE_ARGS} --inspect=0.0.0.0:${DEBUG_PORT}"
	echo "[INFO] Node Inspector enabled on port ${DEBUG_PORT}"
fi

exec node ${NODE_ARGS} /app/dist/index.js
