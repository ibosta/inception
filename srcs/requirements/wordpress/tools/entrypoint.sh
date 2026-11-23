#!/bin/bash
set -e
cd /var/www/html

if [ ! -f wp-config.php ]; then
    wp core download --allow-root --force
    wp config create --allow-root --dbname=$MYSQL_DATABASE --dbuser=$MYSQL_USER \
        --dbpass=$(cat /run/secrets/db_password) --dbhost=mariadb
    wp core install --allow-root --url=https://$DOMAIN_NAME --title=Inception \
        --admin_user=$WP_ADMIN_USER --admin_password=$(cat /run/secrets/wp_admin_password) \
        --admin_email=$WP_ADMIN_EMAIL --skip-email
    wp user create --allow-root $WP_USER $WP_USER_EMAIL \
        --user_pass=$(cat /run/secrets/wp_user_password)
    chown -R www-data:www-data /var/www/html
fi

exec php-fpm8.2 -F
