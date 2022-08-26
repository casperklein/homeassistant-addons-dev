#!/bin/bash

echo "***** Fix permissions.."

while IFS=';' read -r FILE MODE OWNER; do
	chmod "$MODE" "$FILE" 2>/dev/null
	chown "$OWNER" "$FILE" 2>/dev/null
done < /etc/permissions || true
