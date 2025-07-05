#!/bin/bash

# https://docs.pi-hole.net/docker/dhcp/#docker-pi-hole-with-a-bridge-networking
# https://discourse.pi-hole.net/t/dhcp-with-docker-compose-and-bridge-networking/17038

set -ueo pipefail

CONTAINER="addon_0da538cf_pihole"

_status() {
	local BLUE=$'\e[0;34m'
	local RESET=$'\e[0m'

	printf -- '%s' "$BLUE"    # Use blue font color
	printf -- '%(%F %T)T ' -1 # Print current date/time
	printf -- '%s' "$1"       # Print status message
	printf -- '%s\n' "$RESET" # Reset color
}

FORWARD_HOST=$(jq --raw-output '.forward_host' /data/options.json)

if [ -z "$FORWARD_HOST" ]; then
	_status "No IP address for DHCP request forwarding found in the add-on configuration. Auto-detecting internal IP address of Pi-hole.."
	if [ ! -S /var/run/docker.sock ]; then
		_status "Error: Protection mode is enabled!"
		_status "For auto-detecting to work, you'll need to disable protection mode on this add-on."
		exit 1
	fi
	FORWARD_HOST=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CONTAINER")
	if [ -z "$FORWARD_HOST" ]; then
		_status "Error: Audo-detecting failed."
		exit 1
	fi
fi

_status "Forwarding DHCP requests to: $FORWARD_HOST"

# Options are:
# -d               Debug mode, do not change UID, write a pid-file or go into the background.
# -s <server>      Forward DHCP requests to <server>
exec dhcp-helper -d -s "$FORWARD_HOST"
