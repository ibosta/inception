#!/bin/bash
set -e

chown -R mysql:mysql /var/lib/mysql

if [ ! -d /var/lib/mysql/$MYSQL_DATABASE ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql
    mariadbd --user=mysql --bootstrap <<SQL
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '$(cat /run/secrets/db_root_password)';
CREATE DATABASE $MYSQL_DATABASE;
CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$(cat /run/secrets/db_password)';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
SQL
fi

exec mariadbd --user=mysql
