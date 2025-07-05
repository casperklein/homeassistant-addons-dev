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

sedfile -i -E 's|^  "name": "(.*)"|  "name": "\1-dev"|' config.json
sedfile -i -E 's|^  "image": "(.*)"|  "image": "\1-dev"|' config.json
sedfile -i -E 's|^  "slug": "(.*)"|  "slug": "\1-dev"|' config.json
sedfile -i    's|casperklein/homeassistant-addons/tree/master|casperklein/homeassistant-addons-dev/tree/master|' config.json

sedfile -i -E 's|io.hass.name="(.*)"|io.hass.name="\1-dev"|' Dockerfile
sedfile -i -E 's|image="casperklein/homeassistant-(.*):|image="casperklein/homeassistant-\1-dev:|' Dockerfile
sedfile -i    's|casperklein/homeassistant-addons/tree/master|casperklein/homeassistant-addons-dev/tree/master|' Dockerfile

sedfile -i -E 's|casperklein/homeassistant-addons\)|casperklein/homeassistant-addons-dev)|g' README.md
sedfile -i -E 's|casperklein%2Fhomeassistant-addons%2F|casperklein%2Fhomeassistant-addons-dev%2F|g' README.md
sedfile -i -E 's|casperklein%2Fhomeassistant-addons$|casperklein%2Fhomeassistant-addons-dev|g' README.md

sedfile -i -E "s|$1|$1-dev|g" README.md
sedfile -i -E 's|-dev%2Fconfig.json|%2Fconfig.json|g' README.md # Fix version shield

IDENTIFIER_STABLE=$(printf %s https://github.com/casperklein/homeassistant-addons  | sha1sum | head -c8)
IDENTIFIER_DEV=$(printf %s https://github.com/casperklein/homeassistant-addons-dev | sha1sum | head -c8)
sedfile -i "s|$IDENTIFIER_STABLE|$IDENTIFIER_DEV|g" README.md

echo "Info: config.json and Dockerfile successful patched."
echo
