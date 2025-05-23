FROM composer:2
FROM bash:5
FROM php:8.1-alpine

# copy from the images into the PHP Image
COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY --from=bash /usr/local/bin/bash /usr/bin/bash
COPY --from=php:8.1-alpine /usr/local/bin/php /usr/bin/php81

COPY entrypoint.sh /entrypoint.sh

RUN apk --no-cache add php82-cli php83-cli php84-cli \
    php82-common php83-common php84-common \
    php82-curl php83-curl php84-curl \
    php82-intl php83-intl php84-intl \
    php82-openssl php83-openssl php84-openssl \
    php82-phar php83-phar php84-phar \
    php82-soap php83-soap php84-soap \
    php82-xml php83-xml php84-xml \
    php82-zip php83-zip php84-zip \
    php82-mbstring php83-mbstring php84-mbstring

RUN apk update && apk upgrade && \
    apk add git jq libxml2-dev libzip-dev icu-dev curl && \
    rm -rf /var/cache/apk/*

RUN docker-php-ext-install soap && \
    docker-php-ext-install zip && \
    docker-php-ext-configure intl && docker-php-ext-install intl

RUN echo -e "Install typo3/tailor" && \
    composer global require typo3/tailor ^1.7 --prefer-dist --no-progress --no-suggest

RUN ln -nfs /root/.composer/vendor/typo3/tailor/bin/tailor /usr/bin/tailor

ENTRYPOINT ["/entrypoint.sh"]
