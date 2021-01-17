#!/usr/bin/env bash

echo -e "Preparing upload of release $1 to TER\n";

echo -e "Preparing Release"
COMPOSER_PREPARE_RELEASE=$(cat composer.json | jq '.scripts."prepare-release"')

echo "prepare-release: $COMPOSER_PREPARE_RELEASE"
if [ -z "$COMPOSER_PREPARE_RELEASE" ]
then
  echo "You can add a prepare-release to your composer.json to make your zip smaller before uploading, see README.md"
else
  composer prepare-release
fi

EXTKEY=$(cat composer.json | jq '.extra."typo3/cms"."extension-key"')

if [ -z "$EXTKEY" ]
then
  echo "You have to set your extensionkey in composer.json, this will soon be mandatory in all TYPO3 Extensions., see README.md"
fi

TAG_MESSAGE=$(git log -1 --pretty=%B)

echo -e "Extkey: $EXTKEY"
echo -e "Username: ${{ secrets.TYPO3_ORG_USERNAME }}"
echo -e "Password: ${{ secrets.TYPO3_ORG_PASSWORD }}"
echo -e "TagMessage: $TAG_MESSAGE"

#$HOME/.composer/vendor/helhum/ter-client/ter-client upload $1. -u "${{ secrets.TYPO3_ORG_USERNAME }}" -p "${{ secrets.TYPO3_ORG_PASSWORD }}" -m "$TAG_MESSAGE"

