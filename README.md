# Devpi Docker Image

This repository contains the configuration for a robust, secure, and production-ready Docker image for `devpi-server`, a powerful private PyPI server.

This image is designed with a focus on security, data integrity, and ease of use. It includes an intelligent entrypoint script that automatically handles permissions and initialization, as well as a robust health check to ensure the service is running correctly.

## Project Structure

To use this configuration, your project should be organized as follows:

```
/docker-devpi/
├── docker-entrypoint.sh
├── docker-healthcheck.sh
├── Dockerfile
└── requirements.txt
```
- `docker-entrypoint.sh`: The script that handles initialization and permissions.
- `docker-healthcheck.sh`: The script used for the container health check.
- `Dockerfile`: The instructions to build the Docker image.
- `requirements.txt`: Python Requirements

## Configuration

The container is configured using environment variables.

| Variable                    | Description                                                                                             | Required | Default             |
| --------------------------- | ------------------------------------------------------------------------------------------------------- | -------- | ------------------- |
| `DEVPISERVER_ROOT_PASSWORD` | The password for the `root` user. This is **required** for the first time the container is run.           | **Yes**  | `null`              |
| `USER_UID`                  | The UID of the `devpi` user inside the container.                                                       | No       | `1000`              |
| `USER_GID`                  | The GID of the `devpi` group inside the container.                                                      | No       | `1000`              |

## How to Run

The recommended way to run this container is with Docker Compose.

### 1. Create the `docker-compose.yml` File

Use the following `docker-compose.yml` file.

```
services:
  devpi:
    image: ghcr.io/veloslab/devpi
    container_name: devpi_server
    restart: unless-stopped
    ports:
      - "3141:3141"
    environment:
      # IMPORTANT: Change this to a strong, secure password!
      - DEVPISERVER_ROOT_PASSWORD=YourSecretPassword
    volumes:
      # Mounts the local ./data directory to persist devpi data
      - ./data:/var/devpi/server
```

### 2. Set the Root Password

Before you start, **you must change `YourSecretPassword`** in the `docker-compose.yml` file. For production deployments, it is strongly recommended to use Docker Secrets to manage this password instead of placing it directly in the file.

### 3. Start the Server

Open a terminal in the root of your project directory and run the following command:

```
docker-compose up -d
```
- `-d`: Runs the container in detached mode (in the background).

On the first run, the entrypoint script will:
1.  Check that the `./data` directory is exists/is empty.
2.  Set the correct ownership on the `./data` directory.
3.  Initialize `devpi-server` and create the `root` user with the password you provided.

On subsequent runs, it will skip these steps and start the server immediately.

### 4. Verify the Server is Running

After about a minute, you can check the status and health of the container:

```
docker compose ps
```

The `STATUS` column for the `devpi_server` container should show `(healthy)`. If it shows `(health: starting)`, wait a bit longer. If it shows `(unhealthy)`, check the logs for errors:

```
docker-compose logs devpi
```

An unhealthy status typically means the `DEVPISERVER_ROOT_PASSWORD` in your `docker-compose.yml` does not match the password that was set during initialization.

### 5. Accessing the Devpi Server

Once the server is running, you can access the web interface at `http://localhost:3141` and use the `devpi` client to interact with it.

### 6. Stopping the Server

To stop the container and the service, run:

```
docker-compose down
```

Your data will remain safe in the `./data` directory on your host machine.
