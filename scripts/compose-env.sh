#!/usr/bin/env bash
# Writes .env for docker compose from SSM Parameter Store (never commit .env).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
get() { aws ssm get-parameter --name "$1" --with-decryption --query Parameter.Value --output text; }
{
  echo "MYSQL_ROOT_PASSWORD=$(get /roboshop/dev/mysql-root-password)"
  echo "TAG=${TAG:-dev}"
  echo "IMAGE_PREFIX=${IMAGE_PREFIX:-roboshop}"
} > .env
chmod 600 .env
echo "wrote .env (IMAGE_PREFIX=${IMAGE_PREFIX:-roboshop}, TAG=${TAG:-dev})"
