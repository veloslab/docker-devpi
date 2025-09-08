# Stage 1: 'base' - System and User Setup
# This stage prepares the base OS, installs system-level dependencies (gosu),
# and creates the non-root 'devpi' user. These layers are stable and
# will be cached unless the base image or apt packages change.
FROM python:3.13-slim AS base

ARG USER_UID=1000
ARG USER_GID=1000

ENV DEVPISERVER_SERVERDIR /var/devpi/server
ENV DEVPISERVER_PORT 3141
ENV PYTHONWARNINGS=ignore:pkg_resources

RUN apt-get update && \
    apt-get install -y --no-install-recommends gosu && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd --gid $USER_GID devpi && \
    useradd --uid $USER_UID --gid $USER_GID --shell /bin/bash --create-home devpi

RUN mkdir -p $DEVPISERVER_SERVERDIR && chown devpi:devpi $DEVPISERVER_SERVERDIR


# Stage 2: 'builder' - Python Dependency Installation
# This stage is dedicated to installing Python packages. It starts from the 'base'
# stage and only copies the requirements.txt file. Docker will only re-run this
# stage if the contents of requirements.txt change.
FROM base AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt


# Stage 3: 'final' - Final Application Image
# This is the final image. It starts from the clean 'base' stage to keep the
# image lean and secure. It then copies the pre-installed packages from the
# 'builder' stage and adds the application code.
FROM base

# Copy the installed Python packages from the builder stage.
# This is much faster than running pip install again.
COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application scripts that might change frequently.
# Since this is one of the last steps, changes here won't invalidate
# the previous, slow-building stages.
COPY docker-entrypoint.sh /usr/local/bin/
COPY docker-healthcheck.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-healthcheck.sh

# Define runtime configuration
VOLUME $DEVPISERVER_SERVERDIR
EXPOSE 3141

HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
  CMD ["gosu", "devpi", "/usr/local/bin/docker-healthcheck.sh"]

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["devpi-server", "--host=0.0.0.0", "--port=3141", "--serverdir=/var/devpi/server"]
