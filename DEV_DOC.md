# Developer Documentation

This document explains how to set up, build and manage the project as a developer.

## 1. Set up the environment from scratch

### Prerequisites

A Debian virtual machine with:

| Tool            | Check                    |
|-----------------|--------------------------|
| Docker          | `docker --version`       |
| Docker Compose  | `docker compose version` |
| make            | `make --version`         |
| sudo            | `sudo -v`                |

The user `itaskira` must be able to use Docker:
```bash
sudo usermod -aG docker itaskira
```
Then log out and log in again.

### Domain

```bash
echo "127.0.0.1 itaskira.42.fr" | sudo tee -a /etc/hosts
```

### Configuration file: `srcs/.env`

```bash
cp srcs/.env.example srcs/.env
```

It contains the settings that are not secret:

| Variable          | Value                  | Used by            |
|-------------------|------------------------|--------------------|
| `DOMAIN_NAME`     | `itaskira.42.fr`       | wordpress          |
| `MYSQL_DATABASE`  | `wordpress`            | mariadb, wordpress |
| `MYSQL_USER`      | `wpuser`               | mariadb, wordpress |
| `WP_ADMIN_USER`   | `ibrahim`              | wordpress          |
| `WP_ADMIN_EMAIL`  | `ibrahim@example.com`  | wordpress          |
| `WP_USER`         | `writer`               | wordpress          |
| `WP_USER_EMAIL`   | `writer@example.com`   | wordpress          |

### Secrets: `secrets/`

```bash
mkdir secrets
echo "rootpass"   > secrets/db_root_password.txt
echo "dbpass"     > secrets/db_password.txt
echo "bosspass"   > secrets/wp_admin_password.txt
echo "writerpass" > secrets/wp_user_password.txt
```

| File                    | Used by            | Content                         |
|-------------------------|--------------------|---------------------------------|
| `db_root_password.txt`  | mariadb            | Password of the MariaDB root    |
| `db_password.txt`       | mariadb, wordpress | Password of `wpuser`            |
| `wp_admin_password.txt` | wordpress          | Password of the WordPress admin |
| `wp_user_password.txt`  | wordpress          | Password of the second user     |

Inside the containers they are files in `/run/secrets/`. `secrets/` and `srcs/.env`
are listed in `.gitignore`.

## 2. Build and launch

```bash
make
```

`make` does two things:
1. `mkdir -p /home/itaskira/data/mariadb /home/itaskira/data/wordpress`
2. `docker compose -f srcs/docker-compose.yml up -d --build`

Docker Compose then:
1. builds the images `mariadb:inception`, `wordpress:inception`, `nginx:inception`,
2. creates the network and the two volumes,
3. starts `mariadb`, waits until its healthcheck says "healthy",
4. starts `wordpress`, then `nginx`.

On the first start:
- MariaDB creates the database `wordpress` and the user `wpuser`.
- WordPress is downloaded with WP-CLI, configured and installed with its two users.

## 3. Manage the containers and volumes

### Makefile

| Command       | What it runs                                                |
|---------------|-------------------------------------------------------------|
| `make`        | create data folders + `docker compose up -d --build`        |
| `make down`   | `docker compose down`                                       |
| `make clean`  | `docker compose down --rmi all`                             |
| `make fclean` | `docker compose down --rmi all -v` + delete the data folder |
| `make re`     | `make fclean` + `make`                                      |

### Useful Docker commands

| Goal                              | Command                                                  |
|-----------------------------------|----------------------------------------------------------|
| List the containers               | `docker compose -f srcs/docker-compose.yml ps`           |
| Logs of all services              | `docker compose -f srcs/docker-compose.yml logs`         |
| Logs of one service               | `docker logs mariadb`                                    |
| Open a shell in a container       | `docker exec -it wordpress bash`                         |
| Rebuild and restart one service   | `docker compose -f srcs/docker-compose.yml up -d --build nginx` |
| List the networks                 | `docker network ls`                                      |
| List the volumes                  | `docker volume ls`                                       |
| Inspect a volume                  | `docker volume inspect srcs_wordpress_data`              |
| SQL shell                         | `docker exec -it mariadb mariadb -u root -p`             |
| List WordPress users              | `docker exec wordpress wp user list --allow-root`        |

### Change a port (example: NGINX on 8443)

1. `srcs/requirements/nginx/conf/nginx.conf`: `listen 8443 ssl;`
2. `srcs/docker-compose.yml`: `"8443:8443"`
3. `make down && make`
4. WordPress keeps its address in the database, so update it:
   ```bash
   docker exec wordpress wp option update home https://itaskira.42.fr:8443 --allow-root
   docker exec wordpress wp option update siteurl https://itaskira.42.fr:8443 --allow-root
   ```

## 4. Where the data is stored and how it persists

| Volume                | Path in the container | Path on the host                |
|-----------------------|-----------------------|---------------------------------|
| `srcs_mariadb_data`   | `/var/lib/mysql`      | `/home/itaskira/data/mariadb`   |
| `srcs_wordpress_data` | `/var/www/html`       | `/home/itaskira/data/wordpress` |

- Both are Docker named volumes. Their data is written in `/home/itaskira/data`.
- `make down`, `make clean` and a reboot do not delete the data.
- On the next start the scripts see that the data already exists and skip the setup:
  MariaDB checks for `/var/lib/mysql/wordpress`, WordPress checks for `wp-config.php`.
- Only `make fclean` deletes the data.
