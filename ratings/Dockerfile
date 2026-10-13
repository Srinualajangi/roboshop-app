# syntax=docker/dockerfile:1

FROM composer:2 AS composer

FROM php:7.4-apache

# Debian Bullseye archive fix
RUN sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list \
 && sed -i '/security/d' /etc/apt/sources.list \
 && apt-get update \
 && apt-get install -yqq --no-install-recommends unzip libzip-dev \
 && docker-php-ext-install pdo_mysql opcache zip \
 && rm -rf /var/lib/apt/lists/*

# Enable AutoProfile for PHP
RUN echo "instana.enable_auto_profile=1" > "/usr/local/etc/php/conf.d/zzz-instana-extras.ini"

# Relax permissions on status
COPY status.conf /etc/apache2/mods-available/status.conf

# Enable Apache modules
RUN a2enmod rewrite && a2enmod status

# Run Apache on 8080 instead of 80
RUN sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf \
 && sed -i 's/:80/:8080/' /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html

COPY html/ /var/www/html

COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN composer install --no-interaction

# Symfony permissions
RUN rm -rf /var/www/var/* \
 && chown -R www-data:www-data /var/www \
 && chmod -R 777 /var/www

EXPOSE 8080

CMD ["apache2-foreground"]
