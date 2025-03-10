#!/bin/bash

set -ueo pipefail

OPTIONS="/data/options.json"
CONFIG="/dnscrypt-proxy.toml"
SERVICE="/run/service/dnscrypt-proxy"
PH_CONFIG="/data/pihole/setupVars.conf"
# PH_CONFIG="/etc/pihole/pihole.toml" # todo

# Check if there are dnscrypt settings
if ! grep -qF '"dnscrypt": []' "$OPTIONS"; then
	# Only create configuration on first run, in case dnscrypt-proxy crashed and is restarted by s6.
	if ! grep -qF 'server_names' "$CONFIG"; then
		# Read settings
		while read -r SERVER; do
			# {"name":"cloud1","stamp":"sdns://AgcAAAAAAAAABzEuMS4xLjEAEmNsb3VkZmxhcmUtZG5zLmNvbQovZG5zLXF1ZXJ5"}
			NAME+=("$(echo "$SERVER" | base64 -d | cut -d'"' -f4)")
			STAMP+=("$(echo "$SERVER" | base64 -d | cut -d'"' -f8)")
		done < <(jq -r '.dnscrypt[] | @base64' "$OPTIONS")

		# Create custom dnscrypt-proxy configuration
		{
			FIRST=true
			echo -n 'server_names = ['
			for i in "${NAME[@]}"; do
				if [ "$FIRST" = true ]; then
					echo -n "'$i'"
					FIRST=false
				else
					echo -n ",'$i'"
				fi
			done
			echo ']'
			echo "[static]"
		} >> "$CONFIG"

		{
			for i in "${!NAME[@]}"; do
				echo "[static.'${NAME[$i]}']"
				echo "stamp = '${STAMP[$i]}'"
			done
		} >> "$CONFIG"
	fi

	# Check if custom DNS server is properly configured
	# TODO yq -r '.dns.upstreams[]' /etc/pihole/pihole.toml
	if ! grep -qP 'PIHOLE_DNS_[0-9]+=127\.0\.0\.1#5353' "$PH_CONFIG"; then
		echo "WARNING: Custom DNS server 127.0.0.1#5353 is NOT configured. DNSCrypt/DoH name resolution will NOT work until this is fixed."
	else
		# Check for other configured DNS servers
		if grep -qF 'PIHOLE_DNS_2' "$PH_CONFIG"; then
			echo "WARNING: There are more DNS servers configured than 127.0.0.1#5353. Not all DNS querys will be handled by dnscrypt-proxy."
		fi
	fi

	# Start dnscrypt-proxy
	echo "INFO: Starting dnscrypt-proxy."
	/dnscrypt-proxy
else
	# Disable s6 service
	s6-svc -O "$SERVICE"
	echo "INFO: No DNSCrypt/DoH settings found in configuration."
	echo "INFO: NOT starting dnscrypt-proxy."

	# Check if custom DNS server is configured
	if grep -qP 'PIHOLE_DNS_[0-9]+=127\.0\.0\.1#5353' "$PH_CONFIG"; then
		echo "WARNING: Custom DNS server 127.0.0.1#5353 is configured. DNS resolution will NOT work until dnscrypt-proxy is configured in the addon configuration."
	fi
fi
