FROM debian:bullseye

RUN apt-get update && \
    apt-get install -y nginx openssl netcat-openbsd gettext-base && \
    rm -rf /var/lib/apt/lists/*

RUN openssl req -x509 -nodes -days 365 \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/CN=inception" \
    -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx.key \
    -out /etc/ssl/certs/nginx.crt

COPY conf/nginx.conf /etc/nginx/sites-available/default.template
COPY tools/nginx-start.sh /nginx-start.sh
RUN chmod +x /nginx-start.sh

EXPOSE 443

ENTRYPOINT ["/nginx-start.sh"]