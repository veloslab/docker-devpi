#!/bin/sh
set -e

# As root, check if the server directory is empty.
# If it is, we assume it's the first run and fix ownership.
# This avoids changing permissions on existing data on subsequent runs.
if [ -z "$(ls -A "$DEVPISERVER_SERVERDIR")" ]; then
    echo "$DEVPISERVER_SERVERDIR is empty. Setting ownership for devpi user..."
    chown devpi:devpi "$DEVPISERVER_SERVERDIR"
fi

# Now that permissions are correct for an initial run, proceed as the 'devpi' user.
# Check if the server needs to be initialized.
if ! gosu devpi test -f "$DEVPISERVER_SERVERDIR/.nodeinfo"; then
    # On first run, require the root password to be set.
    if [ -z "$DEVPISERVER_ROOT_PASSWORD" ]; then
        echo "Error: DEVPISERVER_ROOT_PASSWORD environment variable is not set." >&2
        echo "You must set a password for the root user for the initial setup." >&2
        exit 1
    fi

    echo "Initializing devpi-server in $DEVPISERVER_SERVERDIR as user devpi..."
    
    # Run initialization non-interactively as the 'devpi' user.
    gosu devpi devpi-init --serverdir "$DEVPISERVER_SERVERDIR" --root-passwd "$DEVPISERVER_ROOT_PASSWORD"
fi

# Start the server as the 'devpi' user.
echo "Starting devpi-server..."
exec gosu devpi "$@"

