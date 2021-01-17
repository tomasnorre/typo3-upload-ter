FROM composer:2
FROM bash:5
FROM php:7.4-alpine

# copy from the images into the PHP Image
COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY --from=bash /usr/local/bin/bash /usr/bin/bash

COPY entrypoint.sh /entrypoint.sh

RUN apk update && apk upgrade && \
    apk add bash git jq libxml2-dev && rm -rf /var/cache/apk/*

RUN docker-php-ext-install soap

ENTRYPOINT ["/entrypoint.sh"]
