#!/bin/bash

set -eu
APP_NAME="start-laravel"

docker compose up -d --no-recreate && \
docker compose exec ${APP_NAME}-app composer install && \
docker compose exec ${APP_NAME}-app npm install && \
docker compose exec ${APP_NAME}-app npm run dev
