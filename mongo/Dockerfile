# syntax=docker/dockerfile:1
# RoboShop MongoDB with seed data (catalogue products + demo users). Runs only on first start with an empty /data/db.
FROM mongo:5.0@sha256:41108d183e972dcbf98d09ed83f6cfc89a471a3f15d06f9d64a95e45d9db8dd2
LABEL org.opencontainers.image.title="roboshop-mongodb"
COPY catalogue.js users.js /docker-entrypoint-initdb.d/
