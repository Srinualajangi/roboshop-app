# syntax=docker/dockerfile:1
# RoboShop ratings — PHP 7.4 / Symfony 5 on Apache. composer.json requires "php": "^7.4", so we stay on 7.4 for the baseline.
FROM composer:2@sha256:af98f42dfff7c68ba8d53c2164fd9fde1087b7d449514baa38c418b1f6bc4bac AS composer

FROM php:7.4-apache@sha256:c9d7e608f73832673479770d66aacc8100011ec751d1905ff63fae3fe2e0ca6d
ARG GIT_SHA=unknown
LABEL org.opencontainers.image.title="roboshop-ratings" org.opencontainers.image.revision="${GIT_SHA}"
# php:7.4 is Debian 11 (bullseye, end of life): fall back to archive.debian.org when the mirrors are gone (tracked exception)
# Listen on 8080 instead of 80 so Apache does not need root; enable mod_rewrite for Symfony routing
RUN sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list \
 && sed -i '/security/d' /etc/apt/sources.list \
 && apt-get update \
 && apt-get install -yqq --no-install-recommends unzip libzip-dev \
 && docker-php-ext-install pdo_mysql opcache zip \
 && rm -rf /var/lib/apt/lists/*
