#!/bin/bash

set -ueo pipefail
shopt -s inherit_errexit

MANAGE_PY=/opt/netbox/netbox/manage.py

# https://github.com/netbox-community/netbox/blob/develop/upgrade.sh
echo "Info: Applying database migrations.."
python3 "$MANAGE_PY" migrate

# Your models in app(s): 'netbox_bgp' have changes that are not yet reflected in a migration, and so won't be applied.
# Run 'manage.py makemigrations' to make new migrations, and then re-run 'manage.py migrate' to apply them.
python3 "$MANAGE_PY" makemigrations
python3 "$MANAGE_PY" migrate

# Trace any missing cable paths (not typically needed)
python3 "$MANAGE_PY" trace_paths --no-input

# TODO Needs reverse proxy for auto-indexing: http://netboxhost/static/docs/ --> http://netboxhost/static/docs/index.html
# TODO https://github.com/netbox-community/netbox/discussions/13165
# Build the local documentation
# mkdocs build

echo "Info: Collecting static files.."
python3 "$MANAGE_PY" collectstatic --no-input

# Delete any stale content types
python3 "$MANAGE_PY" remove_stale_contenttypes --no-input

# Rebuild the search cache (lazily)
python3 "$MANAGE_PY" reindex --lazy

# Delete any expired user sessions
python3 "$MANAGE_PY" clearsessions
