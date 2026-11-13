FROM composer:2 AS composer

FROM alpine:3.24

COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN apk add --no-cache bash curl git jq \
    php83 php84 php85 \
    php83-curl php84-curl php85-curl \
    php83-intl php84-intl php85-intl \
    php83-mbstring php84-mbstring php85-mbstring \
    php83-openssl php84-openssl php85-openssl \
    php83-phar php84-phar php85-phar \
    php83-simplexml php84-simplexml php85-simplexml \
    php83-soap php84-soap php85-soap \
    php83-xml php84-xml php85-xml \
    php83-zip php84-zip php85-zip

# select-php-version.php uses composer/semver for php-version: auto.
RUN COMPOSER_HOME=/opt/tailor /usr/bin/php85 /usr/bin/composer global require \
      typo3/tailor:^2.1 composer/semver:^3.4 --prefer-dist --no-progress

COPY tailor /usr/local/bin/tailor
COPY select-php-version.php /usr/local/lib/ter-uploader/select-php-version.php
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
