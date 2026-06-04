#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

if [ -z "$MYSQL_DATABASE" ]; then echo "ERROR: MYSQL_DATABASE not set"; exit 1; fi
if [ -z "$MYSQL_USER" ]; then echo "ERROR: MYSQL_USER not set"; exit 1; fi

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

mysqld --skip-networking &
MYSQLD_PID=$!

until mysqladmin ping --silent 2>/dev/null; do
    sleep 1
done

# No root password = fresh install; root has password = existing data, ensure user/DB exist
if mysql -u root -e "SELECT 1" >/dev/null 2>&1; then
    echo "Fresh install — initializing database..."
    mysql -u root <<-EOSQL
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        FLUSH PRIVILEGES;
EOSQL
    echo "Database initialized."
else
    echo "Existing data — verifying database and user..."
    mysql -u root -p"${DB_ROOT_PASSWORD}" <<-EOSQL
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        FLUSH PRIVILEGES;
EOSQL
    echo "Database verified."
fi

mysqladmin -u root -p"${DB_ROOT_PASSWORD}" shutdown
wait $MYSQLD_PID

exec mysqld
