#!/usr/bin/env bash

# PHP versions installed in the image, highest first.
SUPPORTED_PHP_VERSIONS="8.5 8.4 8.3"
DEFAULT_PHP_VERSION="8.5"

php_binary() {
  echo "/usr/bin/php${1//./}"
}

# Prints the PHP version for prepare-release. Tailor always runs on PHP 8.5.
# $1: the php-version input; empty or "auto" reads require.php from composer.json.
select_php_version() {
  local requested="$1" constraint version full
  local candidates=()

  if [[ -n "$requested" && "$requested" != "auto" ]]; then
    for version in $SUPPORTED_PHP_VERSIONS; do
      if [[ "$requested" == "$version" ]]; then
        echo "$version"
        return 0
      fi
    done
    echo "::error::PHP $requested is not available. Use one of: $SUPPORTED_PHP_VERSIONS, or auto." >&2
    return 1
  fi

  constraint=$(jq -r '.require.php // empty' composer.json)
  if [[ -z "$constraint" ]]; then
    echo "composer.json requires no PHP version, using PHP $DEFAULT_PHP_VERSION" >&2
    echo "$DEFAULT_PHP_VERSION"
    return 0
  fi

  for version in $SUPPORTED_PHP_VERSIONS; do
    candidates+=("$("$(php_binary "$version")" -r 'echo PHP_VERSION;')")
  done
  if full=$(/usr/bin/php85 /usr/local/lib/ter-uploader/select-php-version.php "$constraint" "${candidates[@]}"); then
    version="${full%.*}"
    echo "composer.json requires PHP $constraint, using PHP $version ($full)" >&2
    echo "$version"
    return 0
  fi

  echo "::warning::No installed PHP version ($SUPPORTED_PHP_VERSIONS) satisfies \"$constraint\" from composer.json, using PHP $DEFAULT_PHP_VERSION" >&2
  echo "$DEFAULT_PHP_VERSION"
}

PHP_VERSION=$(select_php_version "$2") || exit 1
echo "Using PHP $PHP_VERSION for prepare-release"
ln -sf "$(php_binary "$PHP_VERSION")" /usr/local/bin/php

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
