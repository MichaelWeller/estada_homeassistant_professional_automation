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
		return 0
	fi

	if [ -z "${SSH_PASSWORD}" ]; then
		echo "[ERROR] SSH is enabled, but no ssh_password is configured"
		return 1
	fi

	echo "[INFO] Setting up SSH/SFTP..."

	if ! getent group sshusers >/dev/null 2>&1; then
		addgroup -S sshusers >/dev/null 2>&1 || true
	fi

	if id -u "${SSH_USERNAME}" >/dev/null 2>&1; then
		shell="$(getent passwd "${SSH_USERNAME}" | cut -d: -f7 || true)"
		if [ "${shell}" != "/bin/sh" ]; then
			echo "[INFO] Removing existing user ${SSH_USERNAME}..."
			deluser "${SSH_USERNAME}" >/dev/null 2>&1 || true
		fi
	fi

	if ! id -u "${SSH_USERNAME}" >/dev/null 2>&1; then
		echo "[INFO] Creating user ${SSH_USERNAME}..."
		adduser -D -s /bin/sh -G sshusers -h "${RULES_PATH}" "${SSH_USERNAME}"
	fi

	echo "${SSH_USERNAME}:${SSH_PASSWORD}" | chpasswd

	echo "[INFO] Generating SSH keys..."
	if ! ssh-keygen -A 2>&1; then
		echo "[ERROR] Failed to generate SSH keys"
		return 1
	fi

	cat > /etc/ssh/sshd_config.estada <<EOF
Port ${SSH_PORT}
Protocol 2
PasswordAuthentication yes
PermitRootLogin no
PubkeyAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
X11Forwarding no
AllowUsers ${SSH_USERNAME}
PermitTTY no
Subsystem sftp internal-sftp
EOF

	echo "[INFO] Starting SSH daemon..."
	if /usr/sbin/sshd -f /etc/ssh/sshd_config.estada 2>&1; then
		echo "[INFO] ✓ SSH/SFTP enabled on port ${SSH_PORT} for user ${SSH_USERNAME}"
		return 0
	else
		echo "[ERROR] Failed to start SSH daemon"
		return 1
	fi
}


echo "[INFO] Estada Professional Automation starting"
echo "[INFO] rules_path=${RULES_PATH} log_level=${LOG_LEVEL}"

if [ ! -f /app/dist/index.js ]; then
	echo "[ERROR] Missing /app/dist/index.js. Build step likely failed during image creation."
	exit 1
fi

# Setup development services
echo "[INFO] Setting up development services..."
setup_ssh
SETUP_SSH_RESULT=$?

if [ $SETUP_SSH_RESULT -eq 0 ]; then
	echo "[INFO] ✓ SSH/SFTP setup successful"
else
	echo "[WARNING] SSH/SFTP setup had issues (continuing with limited functionality)"
fi

echo "[INFO] Starting Estada Professional Automation runtime..."

NODE_ARGS="--enable-source-maps"
if bashio::config.true 'enable_debug'; then
	NODE_ARGS="${NODE_ARGS} --inspect=0.0.0.0:${DEBUG_PORT}"
	echo "[INFO] ✓ Node Inspector enabled on port ${DEBUG_PORT}"
fi

exec node ${NODE_ARGS} /app/dist/index.js
