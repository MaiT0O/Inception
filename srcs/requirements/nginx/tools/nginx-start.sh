#!/bin/bash
set -e

envsubst '${DOMAIN_NAME}' < /etc/nginx/sites-available/default.template > /etc/nginx/sites-available/default

echo "Waiting for WordPress to be ready..."

until nc -z wordpress 9000; do
    echo "WordPress not ready yet, retrying in 2s..."
    sleep 2
done

echo "WordPress is up! Starting NGINX..."
exec nginx -g "daemon off;"