FROM composer:2
FROM bash:5
FROM php:7.4-alpine

# copy from the images into the PHP Image
COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY --from=bash /usr/local/bin/bash /usr/bin/bash

COPY entrypoint.sh /entrypoint.sh

RUN apk update && apk upgrade && \
    apk add bash git jq libxml2-dev libzip-dev icu-dev curl && \
    rm -rf /var/cache/apk/*

RUN docker-php-ext-install soap && \
    docker-php-ext-install zip && \
    docker-php-ext-configure intl && docker-php-ext-install intl

RUN echo -e "Install typo3/tailor" && \
    composer global require typo3/tailor --prefer-dist --no-progress --no-suggest

RUN ln -nfs /root/.composer/vendor/typo3/tailor/bin/tailor /usr/bin/tailor

ENTRYPOINT ["/entrypoint.sh"]
