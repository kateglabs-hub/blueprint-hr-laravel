FROM php:8.3-cli-bookworm
WORKDIR /var/www/html
RUN apt-get update && apt-get install -y --no-install-recommends libfreetype6-dev libicu-dev libjpeg62-turbo-dev libonig-dev libpng-dev libwebp-dev libxml2-dev libzip-dev nodejs npm && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp && docker-php-ext-install gd intl mbstring opcache pdo_mysql xml zip && rm -rf /var/lib/apt/lists/*
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY . .
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader --no-scripts && npm ci --no-audit --no-fund && npm run build && composer dump-autoload --no-dev --optimize
RUN mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views storage/logs bootstrap/cache && chmod -R ug+rwX storage bootstrap/cache
EXPOSE 10000
CMD ["sh", "-c", "php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=${PORT:-10000}"]