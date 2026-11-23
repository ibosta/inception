FROM debian:bookworm

RUN apt-get update && apt-get install -y nginx openssl && rm -rf /var/lib/apt/lists/*
RUN rm /etc/nginx/sites-enabled/default
RUN openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
    -keyout /etc/ssl/private/inception.key -out /etc/ssl/certs/inception.crt \
    -subj "/CN=itaskira.42.fr"

COPY conf/nginx.conf /etc/nginx/conf.d/inception.conf

CMD ["nginx", "-g", "daemon off;"]
