FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Générer un certificat SSL auto-signé
RUN openssl req -x509 -nodes -days 365 \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/CN=ebansse.42.fr" \
    -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx.key \
    -out /etc/ssl/certs/nginx.crt

COPY conf/nginx.conf /etc/nginx/sites-available/default

EXPOSE 443

# NGINX en foreground — PID 1
CMD ["nginx", "-g", "daemon off;"]