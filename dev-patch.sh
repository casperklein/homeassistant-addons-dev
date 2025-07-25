#!/bin/bash

set -ueo pipefail

if [ $# -ne 1 ]; then
	echo "Error: No directory given"
	echo
	exit 1
fi >&2

cd "$1"

if grep -q dev config.json; then
	echo "Error: Files already patched?"
	echo
	exit 1
fi >&2

# config.json
sedfile -i -E 's|^  "name": "(.*)"|  "name": "\1-dev"|'   config.json # name key
sedfile -i -E 's|^  "image": "(.*)"|  "image": "\1-dev"|' config.json # image key
sedfile -i -E 's|^  "slug": "(.*)"|  "slug": "\1-dev"|'   config.json # slug key
sedfile -i    's|casperklein/homeassistant-addons|&-dev|' config.json # url key

# Dockerfile
sedfile -i -E 's|io.hass.name="(.*)"|io.hass.name="\1-dev"|'                                       Dockerfile # Label io.hass.name
sedfile -i    's|casperklein/homeassistant-addons|&-dev|'                                          Dockerfile # Label url
sedfile -i -E 's|image="casperklein/homeassistant-(.*):|image="casperklein/homeassistant-\1-dev:|' Dockerfile # Label image

# README.md
sedfile -i 's|/homeassistant-addons|&-dev|g'  README.md
sedfile -i 's|2Fhomeassistant-addons|&-dev|g' README.md
sedfile -i "s|$1|&-dev|g" README.md
sedfile -i "s|master%2F$1-dev|master%2F$1|g" README.md # Fix version shield

# Only for pi-hole*
if [[ "$1" == "placeholder-for-future-use" || "$1" == "pi-hole-dhcp-helper" ]]; then
	sedfile -i "s|master/$1-dev|master/$1|g"     README.md # Fix embedded images
else
	# Needed for other add-ons?
	if grep -qF "master/$1-dev" README.md; then
		echo "Error: There may be an unhandled embedded image URL. Please investigate."
		echo
		exit 1
	fi >&2
fi

IDENTIFIER_STABLE=0da538cf #$(printf %s https://github.com/casperklein/homeassistant-addons     | sha1sum | head -c8)
IDENTIFIER_DEV=83ea786c    #$(printf %s https://github.com/casperklein/homeassistant-addons-dev | sha1sum | head -c8)
sedfile -i "s|$IDENTIFIER_STABLE|$IDENTIFIER_DEV|g" README.md

# Only for pi-hole, because HA slug differs from directory name (legacy)
if [ "$1" == "pi-hole" ]; then
	sedfile -i -E 's|_pihole|_pihole-dev|g' README.md
fi

echo "Info: config.json and Dockerfile successful patched."
echo
