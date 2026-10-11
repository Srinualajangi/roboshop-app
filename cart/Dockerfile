# syntax=docker/dockerfile:1
# RoboShop cart — Node.js cart API (Redis). Same pattern as catalogue.
FROM node:22-bookworm-slim

ARG GIT_SHA=unknown
ARG VERSION=0.0.0-dev
ARG SOURCE_URL=https://github.com/Srinualajangi/roboshop-app
LABEL org.opencontainers.image.title="roboshop-cart" \
      org.opencontainers.image.description="RoboShop cart API" \
      org.opencontainers.image.source="${SOURCE_URL}" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.licenses="Apache-2.0"

ENV NODE_ENV=production \
    APP_VERSION=${VERSION}
WORKDIR /opt/server
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts && npm cache clean --force
COPY server.js ./
USER node
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=20s --retries=3 \
  CMD ["node", "-e", "require('http').get('http://127.0.0.1:8080/health',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"]
CMD ["node", "server.js"]
