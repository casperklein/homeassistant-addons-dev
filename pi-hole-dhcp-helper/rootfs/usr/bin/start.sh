#!/bin/bash

set -ueo pipefail

_status() {
	local BLUE=$'\e[0;34m'
	local RESET=$'\e[0m'

	printf -- '%s' "$BLUE"    # Use blue font color
	printf -- '%(%F %T)T ' -1 # Print current date/time
	printf -- '%s' "$1"       # Print status message
	printf -- '%s\n' "$RESET" # Reset color
}

# todo Auto detect IP?

FORWARD_HOST=$(jq --raw-output '.forward_host' /data/options.json)

if [ -z "$FORWARD_HOST" ]; then
	_status "No Forward host configured. Autodetecting.."
	FORWARD_HOST=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' addon_0da538cf_pihole)
fi

_status "Forwarding DHCP requests to: $FORWARD_HOST"

# Options are:
# -d               Debug mode, do not change UID, write a pid-file or go into the background.
# -s <server>      Forward DHCP requests to <server>
exec dhcp-helper -d -s "$FORWARD_HOST"


# todo
# misc.dnsmasq_lines
# dhcp-option=option:dns-server,192.168.x.x
