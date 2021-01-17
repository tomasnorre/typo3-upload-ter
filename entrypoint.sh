#!/usr/bin/env bash

echo -e "Preparing upload of release $2 to TER\n";

echo -e "Preparing Release"
composer prepare-release

TAG_MESSAGE=`git log -1 --pretty=%B`

echo -e "Extensionkey: $1"
echo -e "Tag: $2"
echo -e "Username: $3"
echo -e "Password: $4"
echo -e "TagMessage: $TAG_MESSAGE"

#echo $HOME/.composer/vendor/helhum/ter-client/ter-client upload crawler . -u "${{ secrets.TYPO3_ORG_USERNAME }}" -p "${{ secrets.TYPO3_ORG_PASSWORD }}" -m "$TAG_MESSAGE"

