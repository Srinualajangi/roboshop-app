# syntax=docker/dockerfile:1
# RoboShop catalogue — Node.js product API. Upstream used node:14 + npm install as root.
FROM node:22-bookworm-slim@sha256:c3de60bf2f9dd0ac6370e6117950ff62d6e339527e7472301c9c78a017978392

LABEL org.opencontainers.image.title="roboshop-catalogue" \
      org.opencontainers.image.description="RoboShop product catalogue API" \
      org.opencontainers.image.licenses="Apache-2.0"

ENV NODE_ENV=production
WORKDIR /opt/server

# 1) dependencies first: this layer is reused until package*.json changes
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts && npm cache clean --force

# 2) source last: a code change only rebuilds from here
COPY server.js ./

# files stay root-owned and read-only for the app user; the app never writes to its own code
USER node
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=20s --retries=3 \
  CMD ["node", "-e", "require('http').get('http://127.0.0.1:8080/health',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"]
CMD ["node", "server.js"]
