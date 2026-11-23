# User Documentation

This document explains how to use the Inception stack, without technical details.

## 1. Services provided

| Service   | What it does                                                      |
|-----------|-------------------------------------------------------------------|
| nginx     | The web server. It is the only way into the stack (HTTPS, port 443). |
| wordpress | The website itself (WordPress).                                   |
| mariadb   | The database where WordPress keeps posts, pages, comments and users. |

The website is only reachable with HTTPS: `https://itaskira.42.fr`.
`http://itaskira.42.fr` (port 80) does not work, on purpose.

## 2. Start and stop the project

Run these commands from the root of the project.

| Action                       | Command       |
|------------------------------|---------------|
| Start                        | `make`        |
| Stop (keep the data)         | `make down`   |
| Delete everything, data too  | `make fclean` |

The first start takes a few minutes: the images are built and WordPress is installed.
The next starts are fast and keep all the content.

## 3. Access the website and the administration panel

1. The domain must point to the machine. This is done once:
   ```bash
   echo "127.0.0.1 itaskira.42.fr" | sudo tee -a /etc/hosts
   ```
2. Website: open `https://itaskira.42.fr`.
   The browser shows a warning because the certificate is self-signed.
   Click "Advanced", then "Accept the risk and continue".
3. Administration panel: open `https://itaskira.42.fr/wp-admin`.

## 4. Credentials

Two WordPress accounts are created automatically:

| Account | Role          | Password file                   |
|---------|---------------|---------------------------------|
| ibrahim | Administrator | `secrets/wp_admin_password.txt` |
| writer  | Subscriber    | `secrets/wp_user_password.txt`  |

Database passwords:

| Account  | Password file                  |
|----------|--------------------------------|
| root     | `secrets/db_root_password.txt` |
| wpuser   | `secrets/db_password.txt`      |

To see a password:
```bash
cat secrets/wp_admin_password.txt
```

The account names are in `srcs/.env`. The `secrets/` folder and `srcs/.env` are never
sent to git. Passwords must be set **before the first start**. To change them later,
run `make fclean`, edit the files, then `make`.

## 5. Check that everything works

| Check                              | Command                                      | Expected result                   |
|------------------------------------|----------------------------------------------|-----------------------------------|
| The 3 containers are running       | `docker ps`                                  | 3 lines `Up`, mariadb `(healthy)` |
| The website answers                | `curl -k https://itaskira.42.fr`             | HTML of the website               |
| Port 80 is closed                  | `curl http://itaskira.42.fr`                 | `Connection refused`              |
| See the logs of a service          | `docker logs wordpress`                      | Messages of the service           |
| The database contains WordPress    | `docker exec -it mariadb mariadb -u root -p` then `SHOW DATABASES;` | `wordpress` in the list |
