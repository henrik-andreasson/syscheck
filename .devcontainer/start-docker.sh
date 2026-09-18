#!/usr/bin/env bash
#
# Starts the Docker daemon inside the dev container.
#
# Run from postStartCommand rather than postCreateCommand: the daemon has to be
# brought up on every container start, not only on first creation. There is no
# init system in the container, so nothing else would start it.
set -euo pipefail

# Written before the running check below, so that an already-started daemon still gets
# the client config: Testcontainers' docker-java client otherwise addresses the daemon
# as API 1.32, which Docker Engine 29 refuses (it requires 1.40 or later). docker-java
# reads this file at startup; there is no equivalent environment variable it honours.
if ! grep -qs '^api\.version=' "$HOME/.docker-java.properties"; then
	echo 'api.version=1.44' >>"$HOME/.docker-java.properties"
fi

if docker info >/dev/null 2>&1; then
	echo "Docker daemon already running."
	exit 0
fi

echo "Starting Docker daemon..."
sudo mkdir -p /var/log
# --storage-driver=vfs because /var/lib/docker sits on the container's own overlay root
# filesystem, and neither the overlayfs snapshotter nor overlay2 can mount overlay on
# overlay. vfs copies whole layers instead of stacking them, so it is slower and uses
# more disk, but it is the one driver that works here.
#
# The redirection has to happen inside the root shell: running it directly would have
# the unprivileged calling shell open /var/log/dockerd.log, which it may not write to.
sudo sh -c 'nohup dockerd --storage-driver=vfs >/var/log/dockerd.log 2>&1 &'

for _ in $(seq 1 30); do
	if docker info >/dev/null 2>&1; then
		docker version --format 'Docker ready: client {{.Client.Version}}, server {{.Server.Version}}'
		exit 0
	fi
	sleep 1
done

echo "ERROR: the Docker daemon did not become ready within 30s." >&2
echo "Last 20 lines of /var/log/dockerd.log:" >&2
sudo tail -n 20 /var/log/dockerd.log >&2 || true
echo >&2
echo "The most common cause is the container not running privileged." >&2
exit 1
