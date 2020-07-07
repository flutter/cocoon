#!/bin/bash

cd app_dart
gcloud app deploy --project tvolkert-test --version "version-$1" --no-promote --no-stop-previous-version
