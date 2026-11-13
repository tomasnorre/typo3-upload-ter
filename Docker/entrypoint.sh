#!/usr/bin/env bash

# Prints the PHP version for prepare-release. Tailor always runs on PHP 8.5.
select_php_version() {
  local constraint full
  case "$1" in
    8.3|8.4|8.5) echo "$1"; return ;;
    ""|auto) ;;
    8.1|8.2) echo "::warning::PHP $1 is no longer available. The action uses php-version: auto." >&2 ;;
    *) echo "::error::PHP $1 is not available. Use 8.3, 8.4, 8.5 or auto." >&2; return 1 ;;
  esac

  # The full versions let a constraint such as >=8.4.3 compare with the installed 8.4.x.
  constraint=$(jq -r '.require.php // "*"' composer.json)
  if full=$(php85 /usr/local/lib/ter-uploader/select-php-version.php "$constraint" \
      "$(php85 -r 'echo PHP_VERSION;')" "$(php84 -r 'echo PHP_VERSION;')" "$(php83 -r 'echo PHP_VERSION;')"); then
    echo "composer.json requires PHP $constraint. The action uses PHP $full." >&2
    echo "${full%.*}"
  else
    echo "::warning::No installed PHP version (8.3, 8.4, 8.5) satisfies \"$constraint\" from composer.json. The action uses PHP 8.5." >&2
    echo 8.5
  fi
}

PHP_VERSION=$(select_php_version "$2") || exit 1
echo "Using PHP $PHP_VERSION for prepare-release"
ln -sf "/usr/bin/php${PHP_VERSION//./}" /usr/local/bin/php

echo -e "Preparing git configuration (safe.directory)\n";

git config --global --add safe.directory $PWD

echo -e "Preparing upload of release ${GITHUB_REF#refs/tags/} to TER\n";

# Prepare Tag information
TAG_WITHOUT_V=$(echo ${GITHUB_REF#refs/tags/} | sed 's/v//');
if [[ -z $(git tag -l --format='%(contents)' $TAG_WITHOUT_V) ]]; then
  TAG_MESSAGE=$(git log -1 --pretty=%B)
else
  TAG_MESSAGE=$(git tag -l --format='%(contents)' $TAG_WITHOUT_V)
fi

echo -e "Preparing Release"
COMPOSER_PREPARE_RELEASE=$(cat composer.json | jq '.scripts."prepare-release" // empty')

if [ -n "$COMPOSER_PREPARE_RELEASE" ]
then
  composer prepare-release
else
  echo "You can add a prepare-release to your composer.json to make your zip smaller before uploading, see README.md"
fi

# Fetch extension-key from composer.json
export EXTENSION_KEY=$(cat composer.json | jq -r '.extra."typo3/cms"."extension-key" // empty')
export TYPO3_API_TOKEN=$1

if [ -z "$EXTENSION_KEY" ]
then
  echo "You have to set your extension-key in composer.json, this will soon be mandatory in all TYPO3 Extensions., see README.md"
fi

tailor ter:publish --comment="$TAG_MESSAGE" $TAG_WITHOUT_V
