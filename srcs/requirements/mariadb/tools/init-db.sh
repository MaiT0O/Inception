#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    mysqld_safe --skip-networking &

    # Attendre que MariaDB soit vraiment prêt à accepter des connexions
    echo "Waiting for MariaDB to be ready..."
    until mysqladmin ping --silent 2>/dev/null; do
        echo "Not ready yet..."
        sleep 1
    done
    echo "MariaDB is ready!"

    mysql -u root <<-EOSQL
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        FLUSH PRIVILEGES;
EOSQL

    mysqladmin -u root -p"${DB_ROOT_PASSWORD}" shutdown

    # Attendre que MariaDB soit complètement arrêté
    echo "Waiting for shutdown..."
    until ! mysqladmin ping --silent 2>/dev/null; do
        sleep 1
    done
    echo "Shutdown complete."
fi

echo "Starting MariaDB..."
exec mysqld_safe --user=mysql