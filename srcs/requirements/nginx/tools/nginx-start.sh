#!/bin/bash
set -e

echo "Waiting for WordPress to be ready..."

# Boucle jusqu'à ce que le port 9000 de wordpress réponde
until nc -z wordpress 9000; do
    echo "WordPress not ready yet, retrying in 2s..."
    sleep 2
done

echo "WordPress is up! Starting NGINX..."
exec nginx -g "daemon off;"