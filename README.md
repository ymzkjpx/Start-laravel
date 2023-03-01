# Setup.

```shell
$ docker compose up -d
$ docker compose exec start-laravel-app composer install
$ docker compose exec start-laravel-app npm install
$ docker compose exec start-laravel-app npm run dev
$ php artisan key:generate
```
Access to `http://localhost:8000`


# How to Create an initial version of this project
Install default Laravel project
```bash
$ composer create-project laravel/laravel Start-laravel
```

Remove sail package
```json
    "require-dev": {
        "fakerphp/faker": "^1.9.1",
        "laravel/pint": "^1.0",
-       "laravel/sail": "^1.18",
        "mockery/mockery": "^1.4.4",
        "nunomaduro/collision": "^7.0",
        "phpunit/phpunit": "^10.0",
        "spatie/laravel-ignition": "^2.0"
    },
```

Create `compose.yml`
```yaml
version: '3'
services:
    start-laravel-nginx:
        container_name: "sl-nginx"
        build:
            context: ./docker/nginx
        depends_on:
            - start-laravel-app
        ports:
            - "8000:80"
        volumes:
            - ./:/src

    start-laravel-app:
        container_name: "sl-app"
        build:
            context: ./docker/php
        ports:
            - "5173:5173"
        depends_on:
            - start-laravel-mysql
        volumes:
            - ./:/src
            - /src/node_modules
            - /src/vendor
            - ./docker/php/php.ini:/usr/local/etc/php/php.ini

    start-laravel-mysql:
        build:
            context: ./docker/mysql
        command: --max_allowed_packet=32505856
        container_name: "sl-mysql"
        restart: always
        volumes:
            - ./docker/mysql:/docker-entrypoint-initdb.d
            - ./docker/mysql/lib:/var/lib/mysql
            - ./docker/mysql/logs:/var/log/database
        environment:
            MYSQL_DATABASE: main
            MYSQL_USER: docker
            MYSQL_PASSWORD: docker
            MYSQL_ROOT_PASSWORD: root
            LC_ALL: "C.UTF-8"
        ports:
            - "3306:3306"

    start-laravel-redis:
        image: redis:alpine
        container_name: "sl-redis"
        ports:
            - "16379:6379"
```

Create file-spaces for Dockerfile
```shell
$ mkdir -p ./docker/mysql
$ mkdir -p ./docker/mysql/lib
$ mkdir -p ./docker/mysql/logs
$ mkdir -p ./docker/nginx
$ mkdir -p ./docker/nginx/logs
$ mkdir -p ./docker/php
```

Create `./docker/nginx/Dockerfile` for nginx
```dockerfile
FROM nginx:1.21
COPY ./default.conf /etc/nginx/conf.d/default.conf
```

Create `./docker/nginx/default.conf` for nginx
```shell
server {

    listen 80;
    server_name _;

    client_max_body_size 1G;

    root /src/public;
    index index.php;

    access_log /src/docker/nginx/logs/access.log;
    error_log  /src/docker/nginx/logs/error.log;

    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass start-laravel-app:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
```

Create `./docker/php/Dockerfile` for php
```dockerfile
FROM php:8.1-fpm
EXPOSE 5173

RUN apt-get update \
    && apt-get install -y \
    git \
    zip \
    unzip \
    vim \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libfontconfig1 \
    libxrender1

RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install gd
RUN docker-php-ext-install bcmath
RUN docker-php-ext-install pdo_mysql mysqli exif
RUN cd /usr/bin && curl -s http://getcomposer.org/installer | php && ln -s /usr/bin/composer.phar /usr/bin/composer

ENV NODE_VERSION=16.10.0
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN node --version
RUN npm --version

WORKDIR /src
ADD . /src/storage
RUN chown -R www-data:www-data /src/storage
```

Create `./docker/php/php.ini` for php
```ini
upload_max_filesize=256M
post_max_size=256M
```

Create `./docker/mysql/Dockerfile` for mysql
```dockerfile
FROM mysql:8.0.28

RUN apt-get update \
&& apt-get -y install locales --no-install-recommends \
&& rm -rf /var/lib/apt/lists/*

RUN dpkg-reconfigure locales && \
    locale-gen C.UTF-8 && \
    /usr/sbin/update-locale LANG=C.UTF-8

ADD ./my.cnf /etc/mysql/conf.d/my.cnf
RUN chmod 644 /etc/mysql/conf.d/my.cnf
```

Create `./docker/mysql/my.cnf` for mysql
```shell
[mysqld]
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

# Timezone
default-time-zone=SYSTEM
log_timestamps=SYSTEM

# Error Log
slow_query_log=1
long_query_time=5.0
log_queries_not_using_indexes=0
general_log=1

[mysql]
default-character-set=utf8mb4

[client]
default-character-set=utf8mb4
```

Add script `.gitignore`
```text
〜（中略）〜
/docker/mysql/lib/*
/docker/mysql/logs/*
/docker/nginx/logs/*
```

Grant permissions to files
```shell
$ chmod -R guo+w storage
$ php artisan storage:link
```

Create `./vite.config.js` for vite
```js
import {defineConfig} from 'vite';
import laravel from 'laravel-vite-plugin';

export default defineConfig({
    server: {
        host: true,
        hmr: {
            host: 'localhost',
        },
        watch: {
            usePolling: true,
        },
    },
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
    ],
});
```

Modify `./package.json` for vite.
Add the `--host` Options.
```json
{
    "private": true,
    "scripts": {
+       "dev": "vite --host",
        "build": "vite build"
    },
    "devDependencies": {
        "axios": "^1.1.2",
        "laravel-vite-plugin": "^0.7.2",
        "vite": "^4.0.0"
    }
}
```

Install some initial files
```shell
$ docker compose exec start-laravel-app composer install
$ docker compose exec start-laravel-app npm install
```

Build to docker-compose
```shell
$ docker compose build --no-cache
```


## Running the Project
```shell
$ docker compose up -d
$ docker compose exec start-laravel-app npm run dev
```
### Access to webpage 
Access to http://localhost:8000
Leave the server running during development.

# How to Retry
```shell
$ docker compose stop
$ docker compose down
$ docker compose down --rmi all --volumes
$ docker compose build --no-cache
$ docker compose up -d
$ docker compose exec start-laravel-app composer install
$ docker compose exec start-laravel-app npm install
$ docker compose exec start-laravel-app npm run dev
```

## To exit.
```shell
// Stop the npm
$ Ctrl + c 

// Stop the docker coompose
$ docker compose down
$ docker compose stop
```

### If to reboot case then
```shell
$ docker compose up -d --no-recreate
$ docker compose exec start-laravel-app composer install
$ docker compose exec start-laravel-app npm install
$ docker compose exec start-laravel-app npm run dev
```

# Create Web page
Create `./resources/views/testPage.blade.php`
This statement is important in order to receive the benefits of Vite. 
`@vite(['resources/css/app.css', 'resources/js/app.js'])`

```html
<!doctype html>
<html lang="en">
<head>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Document</title>
</head>
<body>
<h1 class="test-text">テストページ</h1>
</body>
</html>
```

Modify `./routes/web.php` for url routing.
`testPage.blade.php` will be displayed.
```php
<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
-     return view('welcome');
+     return view('testPage');
});
```
Access to `http://localhost:8000`
See the Webpage.


## License
The Laravel framework is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
