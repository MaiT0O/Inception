#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/credentials | grep WP_ADMIN_PASSWORD | cut -d= -f2)
WP_USER_PASSWORD=$(cat /run/secrets/credentials | grep WP_USER_PASSWORD | cut -d= -f2)

# Télécharger WordPress si pas encore présent
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "Downloading WordPress..."

    wp core download --allow-root --path=/var/www/html

    # Créer wp-config.php
    wp config create \
        --allow-root \
        --path=/var/www/html \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --skip-check

    # Attendre que MariaDB soit prête
    echo "Waiting for MariaDB..."
    until wp db check --allow-root --path=/var/www/html 2>/dev/null; do
        sleep 2
    done

    # Installer WordPress
    wp core install \
        --allow-root \
        --path=/var/www/html \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email

    # Créer un second utilisateur (non-admin)
    wp user create \
        --allow-root \
        --path=/var/www/html \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author

    chown -R www-data:www-data /var/www/html
fi

echo "Starting PHP-FPM..."
# Lancer php-fpm en foreground — PID 1
exec php-fpm7.4 -F