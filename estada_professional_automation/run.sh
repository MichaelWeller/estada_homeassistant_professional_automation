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
export ENABLE_SAMBA="$(bashio::config 'enable_samba')"
export SAMBA_SHARE_NAME="$(bashio::config 'samba_share_name')"
export ENABLE_DEBUG="$(bashio::config 'enable_debug')"
export DEBUG_PORT="$(bashio::config 'debug_port')"

mkdir -p "${RULES_PATH}"

check_standard_samba() {
	echo "[INFO] Checking for standard Samba add-on..."
	
	# Try to query add-on info via Supervisor API
	if command -v curl >/dev/null 2>&1; then
		if curl -s -f "http://supervisor/addons/samba" \
			-H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
			-H "Content-Type: application/json" >/dev/null 2>&1; then
			echo "[INFO] ✓ Standard Samba add-on detected (samba)"
			return 0
		fi
	fi
	
	echo "[INFO] Standard Samba add-on not detected"
	return 1
}

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
Subsystem sftp internal-sftp
AllowUsers ${SSH_USERNAME}
PermitTTY yes
AllowTcpForwarding yes
X11Forwarding no
EOF

	if /usr/sbin/sshd -f /etc/ssh/sshd_config.estada; then
		echo "[INFO] SSH/SFTP enabled on port ${SSH_PORT} for user ${SSH_USERNAME}"
	else
		echo "[ERROR] Failed to start SSH/SFTP server"
		return 1
	fi
}

setup_samba() {
	if ! bashio::config.true 'enable_samba'; then
		echo "[INFO] Samba is disabled"
		return
	fi

	echo "[INFO] Setting up Samba share..."

	# Install Samba if not already installed
	if ! command -v smbd >/dev/null 2>&1; then
		echo "[INFO] Installing Samba..."
		apk add --no-cache samba >/dev/null 2>&1 || {
			echo "[ERROR] Failed to install Samba package. Disabling Samba share."
			return
		}
	fi

	# Create Samba config directory
	mkdir -p /etc/samba

	# Generate Samba config
	cat > /etc/samba/smb.conf <<EOF
[global]
	workgroup = WORKGROUP
	server string = Estada Professional Automation
	netbios name = ESTADA-PA
	map to guest = Bad User
	log file = /tmp/samba.log
	max log size = 50
	guest account = nobody

[${SAMBA_SHARE_NAME}]
	path = ${RULES_PATH}
	comment = Estada PA Rules Directory
	browsable = yes
	read only = no
	guest ok = yes
	create mask = 0755
	directory mask = 0755
	force user = nobody
	force group = nogroup
EOF

	# Start Samba
	if smbd -D -s /etc/samba/smb.conf 2>&1 | grep -q "Unable"; then
		echo "[ERROR] Failed to start Samba daemon (smbd)"
		return
	fi

	if nmbd -D -s /etc/samba/smb.conf 2>&1 | grep -q "Unable"; then
		echo "[ERROR] Failed to start Samba NetBIOS daemon (nmbd)"
		return
	fi

	echo "[INFO] Samba share '${SAMBA_SHARE_NAME}' enabled on port 445"
	echo "[INFO] Access via: \\\\<HA_IP>\\${SAMBA_SHARE_NAME}"
}

echo "[INFO] Estada Professional Automation starting"
echo "[INFO] rules_path=${RULES_PATH} log_level=${LOG_LEVEL}"

if [ ! -f /app/dist/index.js ]; then
	echo "[ERROR] Missing /app/dist/index.js. Build step likely failed during image creation."
	exit 1
fi

# Check for standard Samba add-on
check_standard_samba

# Setup development services
if ! setup_ssh; then
	echo "[ERROR] Failed to setup SSH/SFTP. Add-on startup aborted."
	exit 1
fi

setup_samba

NODE_ARGS="--enable-source-maps"
if bashio::config.true 'enable_debug'; then
	NODE_ARGS="${NODE_ARGS} --inspect=0.0.0.0:${DEBUG_PORT}"
	echo "[INFO] Node Inspector enabled on port ${DEBUG_PORT}"
fi

exec node ${NODE_ARGS} /app/dist/index.js
