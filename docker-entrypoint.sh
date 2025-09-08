#!/bin/sh
set -e

# Define the path for the secret file within the server's data directory.
# This ensures it's persisted along with other server data.
SECRET_FILE="$DEVPISERVER_SERVERDIR/.secret"

# As root, check if the server directory is empty.
# If it is, we assume it's the first run and fix ownership.
# This avoids changing permissions on existing data on subsequent runs.
if [ -z "$(ls -A "$DEVPISERVER_SERVERDIR")" ]; then
    echo "$DEVPISERVER_SERVERDIR is empty. Setting ownership for devpi user..."
    chown devpi:devpi "$DEVPISERVER_SERVERDIR"
fi

# Now that permissions are correct for an initial run, proceed as the 'devpi' user.

# On first run, check if the secret file exists. If not, create it as the devpi user.
# This ensures login tokens will be persistent across restarts.
if ! gosu devpi test -f "$SECRET_FILE"; then
    echo "Secret file not found. Generating a new persistent secret at $SECRET_FILE..."
    gosu devpi devpi-gen-secret --path "$SECRET_FILE"
fi

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

# Start the server as the 'devpi' user, now including the persistent secret.
echo "Starting devpi-server"
exec gosu devpi devpi-server --secretfile "$SECRET_FILE" "$@"
