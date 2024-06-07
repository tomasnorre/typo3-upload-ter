#!/usr/bin/env bash

echo -e "Preparing git configuration (safe.directory)\n";

git config --global --add safe.directory $PWD

echo -e "Preparing upload of release ${GITHUB_REF#refs/tags/} to TER\n";

# Prepare Tag information
TAG_WITHOUT_V=$(echo ${GITHUB_REF#refs/tags/} | sed 's/v//');
TAG_MESSAGE=$(git log -1 --pretty=%B)

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
