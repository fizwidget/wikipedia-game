#!/bin/bash

echo "- Checking out deployment branch..."
git checkout gh-pages
echo

echo "- Merging master into deployment branch"
git merge master -m "Merging master"
echo

echo "- Building..."
./build.sh
echo

echo "- Comitting new artefacts..."
git add build/elm.js
git commit -m "Updating build"
echo

echo "- Pushing built result..."
git push -f
echo

echo "- Checking out master..."
git checkout master
echo

echo "- Deployment successful (ﾉ◕ヮ◕)ﾉ*:･ﾟ✧"