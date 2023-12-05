ARG PHP_VERSION=8.2-ubuntu
FROM 10up/wp-php-fpm:${PHP_VERSION}

USER root

# Copy built site
WORKDIR /var/www/html
COPY payload .
RUN mkdir wp-content/uploads && \
    chown 33:33 wp-content/uploads

USER www-data