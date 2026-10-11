# RoboShop service catalogue

Source of truth: the code (grep results, Day 9). Upstream: instana/robot-shop @ 55292e2.

| Service | Language / runtime (upstream base image) | Listens on | Health endpoint | Depends on | Config (env var = default) | Hard-coded (tech debt) |
|---|---|---|---|---|---|---|
| web | nginx 1.21 + AngularJS 1.x static | 8080 | `/` (also `/nginx_status`) | all APIs | `CATALOGUE_HOST`, `USER_HOST`, `CART_HOST`, `SHIPPING_HOST`, `PAYMENT_HOST`, `RATINGS_HOST` (envsubst into nginx template) | upstream ports 8080 (ratings 80) in template |
| catalogue | Node.js (node:14), Express | `CATALOGUE_SERVER_PORT`=8080 | `/health` | mongodb | `MONGO_URL`=mongodb://mongodb:27017/catalogue, `GO_SLOW`=0 (ms delay, fault injection) | — |
| user | Node.js (node:14) | `USER_SERVER_PORT`=8080 | `/health` | mongodb, redis | `MONGO_URL`=mongodb://mongodb:27017/users, `REDIS_HOST`=redis | — |
| cart | Node.js (node:14) | `CART_SERVER_PORT`=8080 | `/health`, `/metrics` | redis, catalogue | `REDIS_HOST`=redis, `CATALOGUE_HOST`=catalogue | catalogue port 8080 in URL |
| shipping | Java 8, Spring Boot 2.3.3, Maven | 8080 (Spring default, `SERVER_PORT` overrides) | `/health` | mysql (db `cities`), cart | `DB_HOST`=mysql, `CART_ENDPOINT`=cart (must include port, e.g. cart:8080) | DB user `shipping` / `secret` |
| ratings | PHP 7.4 + Apache, Symfony 5 | 80 | `/_health` | mysql (db `ratings`), catalogue | `PDO_URL`=mysql:host=mysql;dbname=ratings;charset=utf8mb4, `CATALOGUE_URL`=http://catalogue:8080, `APP_ENV` | DB user `ratings` / `iloveit` |
| payment | Python 3.9, Flask, uWSGI | 8080 (`payment.ini` socket; `SHOP_PAYMENT_PORT` only for `python payment.py`) | `/health`, `/metrics` | cart, user, rabbitmq | `CART_HOST`=cart, `USER_HOST`=user, `AMQP_HOST`=rabbitmq, `PAYMENT_GATEWAY`=https://paypal.com/, `PAYMENT_DELAY_MS`=0 | user/cart port 8080 in URLs; RabbitMQ guest/guest; uwsgi uid/gid=1 |
| dispatch | Go (golang:1.17) | none (worker) | none | rabbitmq | `AMQP_HOST`=rabbitmq, `DISPATCH_ERROR_PERCENT`=0 | RabbitMQ guest/guest, port 5672 |
| mongodb | mongo:5 + `catalogue.js`, `users.js` seed | 27017 | — | — | — | no auth |
| mysql | mysql:5.7 + `10-dump.sql.gz` (cities), `20-ratings.sql` | 3306 | — | — | `MYSQL_DATABASE=cities`, `MYSQL_USER=shipping`, `MYSQL_PASSWORD=secret` | ratings user in SQL file |
| redis | redis:6.2-alpine | 6379 | — | — | — | no auth |
| rabbitmq | rabbitmq:3.8-management-alpine | 5672 (AMQP), 15672 (UI) | — | — | — | default guest user |
| load-gen | Python 3.9 + Locust | — | — | web | `HOST`=http://localhost:8080/, `NUM_CLIENTS`, `RUN_TIME`, `ERROR` | — |

## Fault-injection knobs (useful in Phase 8–12)
- `GO_SLOW` (catalogue): adds latency in ms.
- `PAYMENT_DELAY_MS` (payment): slows payment.
- `DISPATCH_ERROR_PERCENT` (dispatch): fails a % of orders.

## Differences from what I expected (fill in)
- 
