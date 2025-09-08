# Use the official Python 3.13 slim base image
FROM python:3.13-slim

# Set default UID/GID for the devpi user. Can be overridden at build time.
ARG USER_UID=1000
ARG USER_GID=1000

# Set environment variables
ENV DEVPISERVER_SERVERDIR /var/devpi/server
ENV DEVPISERVER_PORT 3141
ENV PYTHONWARNINGS=ignore:pkg_resources

# Install dependencies, gosu for privilege management, and create a non-root user
RUN apt-get update && apt-get install -y --no-install-recommends gosu && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd --gid $USER_GID devpi && \
    useradd --uid $USER_UID --gid $USER_GID --shell /bin/bash --create-home devpi

# Create the server directory and set correct ownership
RUN mkdir -p $DEVPISERVER_SERVERDIR && chown devpi:devpi $DEVPISERVER_SERVERDIR

# Use a volume for persistent storage
VOLUME $DEVPISERVER_SERVERDIR

# Copy requirements and install packages, including devpi-client for the healthcheck
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy entrypoint and healthcheck scripts
COPY docker-entrypoint.sh /usr/local/bin/
COPY docker-healthcheck.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-healthcheck.sh

# Expose the port
EXPOSE 3141

# Add a healthcheck to monitor server status and root password validity.
# It waits 30 seconds before the first check to allow the server to start.
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
  CMD ["gosu", "devpi", "/usr/local/bin/docker-healthcheck.sh"]

# Set the entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]

# The default command to run via the entrypoint.
CMD ["devpi-server", "--host=0.0.0.0", "--port=3141", "--serverdir=/var/devpi/server"]

