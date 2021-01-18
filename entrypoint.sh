#!/usr/bin/env bash

echo -e "Preparing upload of release ${GITHUB_REF#refs/tags/} to TER\n";

TAG_WITHOUT_V=$(echo ${GITHUB_REF#refs/tags/} | sed 's/v//');

echo -e "Install typo3/tailor"
composer global require typo3/tailor --prefer-dist --no-progress --no-suggest

echo -e "Preparing Release"
COMPOSER_PREPARE_RELEASE=$(cat composer.json | jq '.scripts."prepare-release"')

if [ -z "$COMPOSER_PREPARE_RELEASE" ] || [ -n "$COMPOSER_PREPARE_RELEASE" ]
then
  composer prepare-release
else
  echo "You can add a prepare-release to your composer.json to make your zip smaller before uploading, see README.md"
fi

# Fetch extension-key from composer.json
TYPO3_EXTENSION_KEY=$(cat composer.json | jq '.extra."typo3/cms"."extension-key"')
TYPO3_API_TOKEN=$1

if [ -z "TYPO3_EXTENSION_KEY" ]
then
  echo "You have to set your extensionkey in composer.json, this will soon be mandatory in all TYPO3 Extensions., see README.md"
fi

TAG_MESSAGE=$(git log -1 --pretty=%B)

$HOME/.composer/vendor/bin/tailor ter:publish --comment "$TAG_MESSAGE" $TAG_WITHOUT_V

