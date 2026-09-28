#!/bin/sh
set -eu

if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
    php artisan migrate --force
fi

if [ "${RUN_OPTIMIZE:-false}" = "true" ]; then
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
fi

if [ "${RUN_STORAGE_LINK:-false}" = "true" ]; then
    php artisan storage:link || true
fi

exec "$@"
