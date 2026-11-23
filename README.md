*This project has been created as part of the 42 curriculum by itaskira.*

# Inception

## Description

Inception is a system administration project. The goal is to build a small web
infrastructure with **Docker** and **Docker Compose**, inside a virtual machine.

The infrastructure hosts a WordPress website at `https://itaskira.42.fr`. It is made of
three services. Each service runs in its own container, and each container is built from
a Dockerfile written for this project (no ready-made images, only `debian:bookworm` as base).

| Service   | Role                                                         | Port              |
|-----------|--------------------------------------------------------------|-------------------|
| nginx     | Web server, the only entrypoint. HTTPS with TLSv1.2/TLSv1.3. | 443 (open to host)|
| wordpress | WordPress website, PHP is executed by php-fpm.               | 9000 (internal)   |
| mariadb   | Database that stores the WordPress content.                  | 3306 (internal)   |

```
browser --HTTPS 443--> nginx --FastCGI 9000--> wordpress --SQL 3306--> mariadb
                         |                         |                      |
                         +----- wordpress_data ----+                 mariadb_data
                          /home/itaskira/data/wordpress     /home/itaskira/data/mariadb
```

### Use of Docker in this project

- **Docker** builds one image per service from its Dockerfile, and runs each image as a container.
- **Docker Compose** reads `srcs/docker-compose.yml` and creates everything together:
  the 3 containers, the network, the 2 volumes and the secrets.
- The **Makefile** is the only command the user needs: `make` creates the data folders and
  runs `docker compose up --build`.

### Sources included in the project

```
inception/
├── Makefile
├── README.md, USER_DOC.md, DEV_DOC.md
├── .gitignore
└── srcs/
    ├── docker-compose.yml
    ├── .env.example
    └── requirements/
        ├── mariadb/     Dockerfile, conf/50-server.cnf, tools/entrypoint.sh
        ├── wordpress/   Dockerfile, conf/www.conf, tools/entrypoint.sh
        └── nginx/       Dockerfile, conf/nginx.conf, tools/entrypoint.sh
```

- `Dockerfile`: how the image of the service is built.
- `conf/`: configuration of MariaDB, php-fpm and NGINX.
- `tools/entrypoint.sh`: runs when the container starts. On the first start it sets up the
  database or WordPress, then it starts the service.
- `srcs/.env` and `secrets/` are created by the user and are not in the repository.

### Main design choices

- **Base image:** `debian:bookworm`, the penultimate stable version of Debian.
- **One process per container:** each service runs in the foreground and is PID 1
  (`exec` in the scripts, `daemon off;` for NGINX). No infinite loops, no `tail -f`.
- **Automatic setup:** on the first start, MariaDB creates the database and its user,
  and WordPress is installed with WP-CLI with two users (an administrator and a normal user).
  The WordPress installation page is never shown.
- **Start order:** a healthcheck tells Docker when MariaDB is ready, and WordPress only
  starts after that.
- **Passwords:** stored as Docker secrets in `secrets/`. Other settings are in `srcs/.env`.
  Both are ignored by git.
- **TLS certificate:** self-signed, created by the NGINX entrypoint on the first start of the container.

### Virtual Machines vs Docker

| Virtual Machine                              | Docker container                              |
|----------------------------------------------|-----------------------------------------------|
| Emulates a full computer with its own kernel | Isolated process that shares the host kernel  |
| Heavy (GBs), starts in minutes               | Light (MBs), starts in seconds                |
| Very strong isolation                        | Isolation with namespaces and cgroups         |

Docker is lighter and faster, and an image runs the same way on every machine.
In this project both are used: the containers run inside a virtual machine.

### Secrets vs Environment Variables

| Environment variables                        | Docker secrets                                     |
|----------------------------------------------|----------------------------------------------------|
| Easy to use (`.env`, `env_file`)             | Mounted as files in `/run/secrets/`                |
| Visible with `docker inspect`                | Not visible with `docker inspect`                  |
| Given to every process in the container      | Only given to the services that ask for them       |

This project uses environment variables for normal settings (domain, database name,
usernames) and secrets for every password.

### Docker Network vs Host Network

| Host network                                   | Docker bridge network                           |
|------------------------------------------------|-------------------------------------------------|
| The container uses the network of the host     | The containers get their own private network    |
| No isolation, every port is open on the host   | Only published ports are reachable from outside |
| Forbidden in this project                      | Used here: network `inception`                  |

On the bridge network the containers find each other by service name
(`mariadb`, `wordpress`) thanks to the internal DNS of Docker.

### Docker Volumes vs Bind Mounts

| Bind mount                                     | Named volume                                    |
|------------------------------------------------|-------------------------------------------------|
| Mounts any folder of the host                  | Created and managed by Docker, has a name       |
| Not managed by Docker                          | Listed with `docker volume ls`                  |
| Forbidden for the data of this project         | Used here: `mariadb_data`, `wordpress_data`     |

The two named volumes keep their data in `/home/itaskira/data`, so the database and
the website stay after the containers are removed or the machine is rebooted.

## Instructions

Requirements: a Debian virtual machine with Docker, Docker Compose, `make` and `sudo`.

1. Point the domain to the machine:
   ```bash
   echo "127.0.0.1 itaskira.42.fr" | sudo tee -a /etc/hosts
   ```
2. Create the settings file:
   ```bash
   cp srcs/.env.example srcs/.env
   ```
3. Create the passwords (choose your own):
   ```bash
   mkdir secrets
   echo "rootpass"   > secrets/db_root_password.txt
   echo "dbpass"     > secrets/db_password.txt
   echo "bosspass"   > secrets/wp_admin_password.txt
   echo "writerpass" > secrets/wp_user_password.txt
   ```
4. Build and start:
   ```bash
   make
   ```
5. Open `https://itaskira.42.fr` and accept the self-signed certificate warning.

| Command       | Effect                                              |
|---------------|-----------------------------------------------------|
| `make`        | Build the images and start the containers           |
| `make down`   | Stop and remove the containers (data is kept)       |
| `make clean`  | Same as `down`, and remove the images               |
| `make fclean` | Same as `clean`, and delete the volumes and data    |
| `make re`     | `fclean`, then `make`                               |

More details: [USER_DOC.md](USER_DOC.md) for users, [DEV_DOC.md](DEV_DOC.md) for developers.

## Resources

- Docker documentation: https://docs.docker.com/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Docker Compose file reference: https://docs.docker.com/reference/compose-file/
- Docker secrets in Compose: https://docs.docker.com/compose/how-tos/use-secrets/
- NGINX documentation: https://nginx.org/en/docs/
- PHP-FPM configuration: https://www.php.net/manual/en/install.fpm.configuration.php
- MariaDB documentation: https://mariadb.com/kb/en/documentation/
- WP-CLI commands: https://developer.wordpress.org/cli/commands/

### Use of AI


- **Documentation:** help to write and translate `README.md`, `USER_DOC.md` and `DEV_DOC.md` into English.
- **Review:** review of the entrypoint scripts and the Makefile (for example, which
  `FLUSH PRIVILEGES` is needed in the MariaDB bootstrap, idempotent WordPress setup,
  checks for missing secrets).
- **Explanations:** clarifying concepts such as Docker secrets, PID 1 and `exec`,
  named volumes vs bind mounts.

Every suggestion was read, tested in the virtual machine and understood before being kept.
