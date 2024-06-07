#!/bin/bash

# Run Laravel migrations
php /var/www/html/artisan migrate --force
php /var/www/html/artisan storage:link
php /var/www/html/artisan scribe:generate

# Start Supervisor
exec "$@"
