#!/bin/bash

cd app_dart
version="version-$1"
gcloud app deploy --project tvolkert-test --version "$version" --no-promote --no-stop-previous-version
