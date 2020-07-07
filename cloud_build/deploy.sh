#!/bin/bash
#
# Deploy a new flutter dashboard version to google cloud.

cd app_dart
gcloud app deploy --project flutter-dashboard --version "version-$1" --no-promote --no-stop-previous-version
