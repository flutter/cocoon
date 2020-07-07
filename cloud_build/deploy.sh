#!/bin/bash

cd app_dart
gcloud app deploy --project tvolkert-test --version version-$SHORT_SHA --no-promote --no-stop-previous-version
