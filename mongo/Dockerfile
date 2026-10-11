# syntax=docker/dockerfile:1
# RoboShop MongoDB with seed data (catalogue products + demo users). Runs only on first start with an empty /data/db.
FROM mongo:5.0
LABEL org.opencontainers.image.title="roboshop-mongodb"
COPY catalogue.js users.js /docker-entrypoint-initdb.d/
