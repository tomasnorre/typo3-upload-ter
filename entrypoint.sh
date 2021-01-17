#!/usr/bin/env bash

echo -e "Preparing upload of release ${GITHUB_REF#refs/tags/} to TER\n";

echo -e "Preparing Release"
COMPOSER_PREPARE_RELEASE=$(cat composer.json | jq '.scripts."prepare-release"')

if [ -z "$COMPOSER_PREPARE_RELEASE" ] || [ -n "$COMPOSER_PREPARE_RELEASE" ]
then
  composer prepare-release
else
  echo "You can add a prepare-release to your composer.json to make your zip smaller before uploading, see README.md"
fi

# Fetch extensionkey from composer.json
EXTKEY=$(cat composer.json | jq '.extra."typo3/cms"."extension-key"')

if [ -z "$EXTKEY" ]
then
  echo "You have to set your extensionkey in composer.json, this will soon be mandatory in all TYPO3 Extensions., see README.md"
fi

TAG_MESSAGE=$(git log -1 --pretty=%B)

$HOME/.composer/vendor/helhum/ter-client/ter-client upload $EXTKEY . -u "$1" -p "$2" -m "$TAG_MESSAGE"

