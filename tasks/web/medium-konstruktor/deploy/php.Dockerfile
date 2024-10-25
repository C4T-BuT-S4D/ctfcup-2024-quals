FROM php:8.2-fpm

WORKDIR /var/www/html

# RUN docker-php-ext-install pdo pdo_mysql

# Copy the source code to the container
COPY ./src /var/www/html
COPY php_entry.sh /php_entry.sh

# Set correct permissions (optional)
RUN chown -R www-data:www-data /var/www/html

# Expose port 9000 for PHP-FPM
EXPOSE 9000

CMD [ "/php_entry.sh" ]