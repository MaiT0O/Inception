FROM debian:bullseye

RUN apt-get update && \
    apt-get install -y nginx openssl netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

# Générer le certificat SSL
RUN openssl req -x509 -nodes -days 365 \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/CN=yourlogin.42.fr" \
    -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx.key \
    -out /etc/ssl/certs/nginx.crt

COPY conf/nginx.conf /etc/nginx/sites-available/default
COPY tools/nginx-start.sh /nginx-start.sh
RUN chmod +x /nginx-start.sh

EXPOSE 443

# Le script attend WordPress puis lance nginx
ENTRYPOINT ["/nginx-start.sh"]