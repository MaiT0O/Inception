#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/credentials | grep WP_ADMIN_PASSWORD | cut -d= -f2)
WP_USER_PASSWORD=$(cat /run/secrets/credentials | grep WP_USER_PASSWORD | cut -d= -f2)

wait_for_mariadb() {
    local host="mariadb"
    local port="3306"
    local max=30
    local attempt=0

    while [ $attempt -lt $max ]; do
        if nc -z "$host" "$port" 2>/dev/null; then
            echo "MariaDB port is open, testing connection..."
            if mysql -h "$host" -u "${MYSQL_USER}" -p"${DB_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; then
                echo "MariaDB is ready!"
                return 0
            fi
        fi
        attempt=$((attempt + 1))
        echo "Attempt $attempt/$max - waiting for MariaDB..."
        sleep 2
    done

    echo "ERROR: MariaDB did not become ready in time"
    exit 1
}

if [ -f "/var/www/html/wp-config.php" ]; then
    echo "wp-config.php already exists. Checking database connection..."
    if wp db check --allow-root --path=/var/www/html >/dev/null 2>&1; then
        echo "Database connection is healthy."
    else
        echo "Database is not ready yet. Waiting for MariaDB..."
        wait_for_mariadb
    fi

    if ! wp core is-installed --allow-root --path=/var/www/html >/dev/null 2>&1; then
        echo "WordPress not installed yet, running install..."
        wp core install \
            --allow-root \
            --path=/var/www/html \
            --url="https://${DOMAIN_NAME}" \
            --title="${WP_TITLE}" \
            --admin_user="${WP_ADMIN_USER}" \
            --admin_password="${WP_ADMIN_PASSWORD}" \
            --admin_email="${WP_ADMIN_EMAIL}" \
            --skip-email
        wp user create \
            --allow-root \
            --path=/var/www/html \
            "${WP_USER}" "${WP_USER_EMAIL}" \
            --user_pass="${WP_USER_PASSWORD}" \
            --role=author
        chown -R www-data:www-data /var/www/html
    fi
else
    if [ ! -d "/var/www/html/wp-includes" ]; then
        echo "Downloading WordPress..."
        wp core download --allow-root --path=/var/www/html
    else
        echo "WordPress files already present, skipping download."
    fi

    wp config create \
        --allow-root \
        --path=/var/www/html \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --skip-check

    echo "Waiting for MariaDB to be accessible..."
    wait_for_mariadb

    wp core install \
        --allow-root \
        --path=/var/www/html \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email

    wp user create \
        --allow-root \
        --path=/var/www/html \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author

    chown -R www-data:www-data /var/www/html
fi

echo "Starting PHP-FPM..."
exec php-fpm7.4 -F
