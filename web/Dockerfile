# syntax=docker/dockerfile:1
# RoboShop web — static AngularJS + nginx reverse proxy to the APIs. Upstream: nginx:1.21.6 as root + Instana entrypoint.
FROM nginxinc/nginx-unprivileged:1.28-alpine
ARG GIT_SHA=unknown
LABEL org.opencontainers.image.title="roboshop-web" org.opencontainers.image.revision="${GIT_SHA}"

# defaults for docker compose; Kubernetes overrides them per environment
ENV CATALOGUE_HOST=catalogue USER_HOST=user CART_HOST=cart \
    SHIPPING_HOST=shipping PAYMENT_HOST=payment RATINGS_HOST=ratings

# nginx's own entrypoint renders /etc/nginx/templates/*.template → /etc/nginx/conf.d/
COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY static/ /usr/share/nginx/html/
# index.html includes eum.html via SSI; upstream generated it at start-up as root. We bake the empty version in at build time.
COPY static/empty.html /usr/share/nginx/html/eum.html

EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3 \
  CMD ["wget", "-q", "-O", "/dev/null", "http://127.0.0.1:8080/"]
