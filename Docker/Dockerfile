FROM composer:2 AS composer

# Alpine 3.24 ships PHP 8.3, 8.4 and 8.5 as packages. No Alpine release
# ships PHP 8.2 and 8.5 together.
FROM alpine:3.24

COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN for v in 83 84 85; do \
      set -- "$@" php$v php$v-curl php$v-intl php$v-mbstring php$v-openssl php$v-phar \
        php$v-simplexml php$v-soap php$v-xml php$v-zip; \
    done && \
    apk add --no-cache bash curl git jq "$@"

# Tailor always runs on PHP 8.5, whatever version prepare-release uses.
# composer/semver is used by select-php-version.php to resolve "auto".
RUN echo "Install typo3/tailor" && \
    COMPOSER_HOME=/opt/tailor /usr/bin/php85 /usr/bin/composer global require \
      typo3/tailor:^2.1 composer/semver:^3.4 --prefer-dist --no-progress && \
    printf '#!/bin/sh\nexec /usr/bin/php85 /opt/tailor/vendor/bin/tailor "$@"\n' > /usr/local/bin/tailor && \
    chmod +x /usr/local/bin/tailor

COPY select-php-version.php /usr/local/lib/ter-uploader/select-php-version.php
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
