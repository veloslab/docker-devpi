#!/bin/sh
# This script performs a health check by attempting to log in to the devpi server.

# Exit immediately if a command exits with a non-zero status.
set -e

# Point the devpi client to the local server. Suppress stdout to keep logs clean.
devpi use "http://localhost:${DEVPISERVER_PORT}" > /dev/null

# Attempt to log in as the root user using the password from the environment variable.
# The command will fail if the login is unsuccessful, causing the script to exit with an error.
devpi login root --password "${DEVPISERVER_ROOT_PASSWORD}" > /dev/null

