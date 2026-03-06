#!/bin/sh
# Check that the devpi HTTP API is responding.
curl -sf "http://localhost:${DEVPISERVER_PORT}/+api/" > /dev/null
