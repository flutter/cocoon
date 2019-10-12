#!/bin/bash

echo "Project: $GCLOUD_PROJECT"
echo "Version: $VERSION"

# Build the Flutter project and copy over to app_dart
pushd ../app_flutter > /dev/null
flutter build web
popd > /dev/null
cp -r ../app_flutter/build build

gcloud app deploy \
    --project "$GCLOUD_PROJECT" \
    --no-promote \
    --no-stop-previous-version \
    --version "$VERSION"