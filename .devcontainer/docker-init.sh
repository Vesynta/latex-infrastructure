#!/usr/bin/env bash
# docker-outside-of-docker init: align the container docker group to the host
# socket GID, or socat-proxy when the socket is root-owned.
# Derived from Microsoft's MIT-licensed docker-init.sh
# (https://github.com/devcontainers/features/tree/main/src/docker-outside-of-docker).
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316
#-------------------------------------------------------------------------------------------------------------

set -e

USERNAME="${DOCKER_INIT_USERNAME:-appuser}"
SOURCE_SOCKET="/var/run/docker-host.sock"
TARGET_SOCKET="/var/run/docker.sock"

SOCAT_PATH_BASE=/tmp/docker-socket-proxy
SOCAT_LOG=${SOCAT_PATH_BASE}.log
SOCAT_PID=${SOCAT_PATH_BASE}.pid

sudoIf() {
	if [ "$(id -u)" -ne 0 ]; then
		sudo "$@"
	else
		"$@"
	fi
}

log() {
	echo -e "[$(date)] $*" | sudoIf tee -a "${SOCAT_LOG}" >/dev/null
}

echo -e "\n** $(date) **" | sudoIf tee -a "${SOCAT_LOG}" >/dev/null
log "Ensuring ${USERNAME} has access to ${SOURCE_SOCKET} via ${TARGET_SOCKET}"

if [ -S "${SOURCE_SOCKET}" ]; then
	SOCKET_GID=$(stat -c '%g' "${SOURCE_SOCKET}")
	DOCKER_GID=$(getent group docker | cut -d: -f3 || true)
	if [ "${SOCKET_GID}" != "0" ] && [ "${SOCKET_GID}" != "${DOCKER_GID}" ] &&
		! grep -Eq ".+:x:${SOCKET_GID}:" /etc/group; then
		sudoIf groupmod --gid "${SOCKET_GID}" docker
	else
		if [ ! -f "${SOCAT_PID}" ] || ! ps -p "$(cat "${SOCAT_PID}")" >/dev/null; then
			log "Enabling socket proxy."
			log "Proxying ${SOURCE_SOCKET} to ${TARGET_SOCKET} for ${USERNAME}"
			sudoIf rm -rf "${TARGET_SOCKET}"
			(
				sudoIf socat UNIX-LISTEN:"${TARGET_SOCKET}",fork,mode=660,user="${USERNAME}",backlog=128 UNIX-CONNECT:"${SOURCE_SOCKET}" 2>&1 |
					sudoIf tee -a "${SOCAT_LOG}" >/dev/null &
				echo "$!" | sudoIf tee "${SOCAT_PID}" >/dev/null
			)
		else
			log "Socket proxy already running."
		fi
	fi
	log "Success"
fi

set +e
exec "$@"
