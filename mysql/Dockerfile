# syntax=docker/dockerfile:1
# RoboShop MySQL 5.7 with seed data: cities (shipping) + ratings schema.
# 20-ratings.sql uses "GRANT ... IDENTIFIED BY", which MySQL 8 removed — that is why we stay on 5.7 for the baseline.
FROM mysql:5.7
LABEL org.opencontainers.image.title="roboshop-mysql"
# non-secret defaults; MYSQL_ROOT_PASSWORD must be supplied at runtime
ENV MYSQL_DATABASE=cities \
    MYSQL_USER=shipping \
    MYSQL_PASSWORD=secret
COPY scripts/10-dump.sql.gz scripts/20-ratings.sql /docker-entrypoint-initdb.d/
