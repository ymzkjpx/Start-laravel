#!/bin/bash

set -eu
APP_NAME="start-laravel"

docker compose stop && \
docker compose down && \
docker compose down --rmi all --volumes
