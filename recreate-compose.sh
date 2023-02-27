#!/bin/bash

set -eu
APP_NAME="start-laravel"

docker compose stop && \
docker compose down && \
docker compose down --rmi all --volumes && \
docker compose build --no-cache && \
docker compose up -d --no-recreate && \
docker compose exec ${APP_NAME}-app composer install && \
docker compose exec ${APP_NAME}-app npm install && \
docker compose exec ${APP_NAME}-app npm run dev && \
php artisan key:generate
