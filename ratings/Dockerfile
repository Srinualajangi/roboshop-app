# syntax=docker/dockerfile:1
# RoboShop ratings — PHP 7.4 / Symfony 5 on Apache. composer.json requires "php": "^7.4", so we stay on 7.4 for the baseline.
FROM composer:2 AS composer

FROM php:7.4-apache
ARG GIT_SHA=unknown
LABEL org.opencontainers.image.title="roboshop-ratings" org.opencontainers.image.revision="${GIT_SHA}"
# php:7.4 is Debian 11 (bullseye, end of life): fall back to archive.debian.org when the mirrors are gone (tracked exception)
RUN (apt-get update || { sed -i 's|deb.debian.org|archive.debian.org|g; /security/d' /etc/apt/sources.list && apt-get update; }) \
 && apt-get install -yqq --no-install-recommends unzip libzip-dev \
 && docker-php-ext-install pdo_mysql opcache zip \
 && rm -rf /var/lib/apt/lists/*
# Listen on 8080 instead of 80 so Apache does not need root; enable mod_rewrite for Symfony routing
RUN a2enmod rewrite \
 && sed -i 's/^Listen 80$/Listen 8080/' /etc/apache2/ports.conf \
 && sed -i 's/<VirtualHost \*:80>/<VirtualHost *:8080>/' /etc/apache2/sites-available/000-default.conf
WORKDIR /var/www/html
COPY html/ /var/www/html/
COPY --from=composer /usr/bin/composer /usr/local/bin/composer
RUN rm -f info.php \
 && composer install --no-dev --no-interaction --optimize-autoloader \
 && rm /usr/local/bin/composer \
 && chown -R www-data:www-data /var/www/html/var
ENV APP_ENV=prod
# numeric uid:gid (www-data) so Kubernetes runAsNonRoot can verify it
USER 33:33
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=20s --retries=3 \
  CMD ["curl", "-fsS", "http://127.0.0.1:8080/_health"]
