#!/bin/bash

cd app_dart
gcloud app deploy --project tvolkert-test --version testkeyonghan --no-promote --no-stop-previous-version
