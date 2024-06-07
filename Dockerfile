FROM node:21-alpine as node-build
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install
COPY . .
RUN yarn run build
FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    libfreetype-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    zlib1g-dev \
    redis-server \
    supervisor \
    git \
    unzip \
    libsodium-dev \
    libgmp-dev \
    nginx \
    libpq-dev

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql pdo_pgsql sodium gmp pcntl
COPY --from=composer:2.1 /usr/bin/composer /usr/bin/composer
RUN composer global self-update

WORKDIR /var/www/html
COPY . /var/www/html
COPY --from=node-build /app/public/build /var/www/html/public/build

RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

COPY .deploy/.nginx/server.conf /etc/nginx/sites-enabled/default
COPY .deploy/supervisor/supervisor.conf /etc/supervisor/conf.d/laravel.conf
COPY .deploy/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN composer install --no-dev --optimize-autoloader
EXPOSE 80
EXPOSE 6000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
