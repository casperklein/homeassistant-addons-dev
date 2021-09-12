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
sedfile -i    's|casperklein/homeassistant-addons/tree/master|casperklein/homeassistant-addons-dev/tree/master|' config.json

sedfile -i -E 's|io.hass.name="(.*)"|io.hass.name="\1-dev"|' Dockerfile
sedfile -i -E 's|image="casperklein/homeassistant-(.*):|image="casperklein/homeassistant-\1-dev:|' Dockerfile
sedfile -i    's|casperklein/homeassistant-addons/tree/master|casperklein/homeassistant-addons-dev/tree/master|' Dockerfile

echo "Info: config.json and Dockerfile successful patched."
echo
