FROM composer:2 AS composer
FROM php:8.5-alpine

COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY entrypoint.sh /entrypoint.sh

# Tailor needs ext-zip. The entrypoint needs bash, git and jq.
RUN apk add --no-cache bash git jq libzip-dev && \
    docker-php-ext-install zip

ENV COMPOSER_HOME=/opt/composer
RUN composer global require typo3/tailor:^2.1 --prefer-dist --no-progress && \
    ln -nfs /opt/composer/vendor/bin/tailor /usr/bin/tailor

ENTRYPOINT ["/entrypoint.sh"]
