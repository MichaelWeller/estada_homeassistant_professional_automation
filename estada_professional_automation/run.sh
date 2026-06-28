#!/usr/bin/with-contenv bashio

set -Eeuo pipefail

export NODE_ENV=production
export HA_URL="ws://supervisor/core/websocket"
export RULES_PATH="$(bashio::config 'rules_path')"
export LOG_LEVEL="$(bashio::config 'log_level')"
export ENABLE_SSH="$(bashio::config 'enable_ssh')"
export SSH_PORT="$(bashio::config 'ssh_port')"
export SSH_USERNAME="$(bashio::config 'ssh_username')"
export SSH_PASSWORD="$(bashio::config 'ssh_password')"
export ENABLE_DEBUG="$(bashio::config 'enable_debug')"
export DEBUG_PORT="$(bashio::config 'debug_port')"

mkdir -p "${RULES_PATH}"

setup_ssh() {
	if ! bashio::config.true 'enable_ssh'; then
		echo "[INFO] SSH is disabled"
		return
	fi

	if [ -z "${SSH_PASSWORD}" ]; then
		echo "[ERROR] SSH is enabled, but no ssh_password is configured"
		exit 1
	fi

	if ! getent group sshusers >/dev/null 2>&1; then
		addgroup -S sshusers >/dev/null 2>&1 || true
	fi

	if id -u "${SSH_USERNAME}" >/dev/null 2>&1; then
		shell="$(getent passwd "${SSH_USERNAME}" | cut -d: -f7 || true)"
		if [ "${shell}" != "/bin/sh" ]; then
			deluser "${SSH_USERNAME}" >/dev/null 2>&1 || true
		fi
	fi

	if ! id -u "${SSH_USERNAME}" >/dev/null 2>&1; then
		adduser -D -s /bin/sh -G sshusers -h "${RULES_PATH}" "${SSH_USERNAME}"
	fi

	echo "${SSH_USERNAME}:${SSH_PASSWORD}" | chpasswd
	ssh-keygen -A >/dev/null 2>&1

	cat > /etc/ssh/sshd_config.estada <<EOF
Port ${SSH_PORT}
Protocol 2
PasswordAuthentication yes
PermitRootLogin no
PubkeyAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
UsePAM no
Subsystem sftp internal-sftp
AllowUsers ${SSH_USERNAME}
PermitTTY yes
AllowTcpForwarding yes
X11Forwarding no
EOF

	/usr/sbin/sshd -f /etc/ssh/sshd_config.estada
	echo "[INFO] SSH/SFTP enabled on port ${SSH_PORT} for user ${SSH_USERNAME}"
}

echo "[INFO] Estada Professional Automation starting"
echo "[INFO] rules_path=${RULES_PATH} log_level=${LOG_LEVEL}"

if [ ! -f /app/dist/index.js ]; then
	echo "[ERROR] Missing /app/dist/index.js. Build step likely failed during image creation."
	exit 1
fi

setup_ssh

NODE_ARGS="--enable-source-maps"
if bashio::config.true 'enable_debug'; then
	NODE_ARGS="${NODE_ARGS} --inspect=0.0.0.0:${DEBUG_PORT}"
	echo "[INFO] Node Inspector enabled on port ${DEBUG_PORT}"
fi

exec node ${NODE_ARGS} /app/dist/index.js
