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

sedfile -i -E 's|^  "name": "(.*)"|  "name": "\1-dev"|'   config.json
sedfile -i -E 's|^  "image": "(.*)"|  "image": "\1-dev"|' config.json
sedfile -i -E 's|^  "slug": "(.*)"|  "slug": "\1-dev"|'   config.json
sedfile -i    's|casperklein/homeassistant-addons/tree/master|casperklein/homeassistant-addons-dev/tree/master|' config.json

sedfile -i -E 's|io.hass.name="(.*)"|io.hass.name="\1-dev"|' Dockerfile
sedfile -i -E 's|image="casperklein/homeassistant-(.*):|image="casperklein/homeassistant-\1-dev:|' Dockerfile
sedfile -i    's|casperklein/homeassistant-addons/tree/master|casperklein/homeassistant-addons-dev/tree/master|' Dockerfile

# sedfile -i -E 's|casperklein/homeassistant-addons\)|casperklein/homeassistant-addons-dev)|g' README.md
# sedfile -i -E 's|casperklein%2Fhomeassistant-addons%2F|casperklein%2Fhomeassistant-addons-dev%2F|g' README.md
# sedfile -i -E 's|casperklein%2Fhomeassistant-addons$|casperklein%2Fhomeassistant-addons-dev|g' README.md

sedfile -i 's|/homeassistant-addons|/homeassistant-addons-dev|g'   README.md
sedfile -i 's|2Fhomeassistant-addons|2Fhomeassistant-addons-dev|g' README.md


sedfile -i "s|$1|$1-dev|g" README.md
#sedfile -i 's|-dev%2Fconfig.json|%2Fconfig.json|g' README.md # Fix version shield
sedfile -i "s|master%2F$1-dev|master%2F$1|g" README.md # Fix version shield

# Only for pi-hole-dhcp-helper
if [ "$1" == "pi-hole-dhcp-helper" ]; then
	sedfile -i "s|master/$1-dev|master/$1|g"     README.md # Fix embedded images
fi

IDENTIFIER_STABLE=$(printf %s https://github.com/casperklein/homeassistant-addons  | sha1sum | head -c8)
IDENTIFIER_DEV=$(printf %s https://github.com/casperklein/homeassistant-addons-dev | sha1sum | head -c8)
sedfile -i "s|$IDENTIFIER_STABLE|$IDENTIFIER_DEV|g" README.md

# Only for pi-hole, because HA slug differs from directory name (legacy)
if [ "$1" == "pi-hole" ]; then
	sedfile -i -E 's|_pihole|_pihole-dev|g' README.md
fi

echo "Info: config.json and Dockerfile successful patched."
echo
