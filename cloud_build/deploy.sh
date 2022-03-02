#!/bin/bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Deploy a new flutter dashboard version to google cloud.

pushd app_dart > /dev/null
set -e
# app_dart
gcloud app deploy --project "$1" --version "version-$2" -q "$3" --no-stop-previous-version
gcloud app deploy --project "$1" cron.yaml
gcloud app services set-traffic default --splits version-$2=1 --quiet
# Google Cloud quota only allows 30 versions.
# For daily builds, this will keep the 10 most recent versions, but wipe the rest.
gcloud app versions list --format="value(version.id)" --sort-by="~version.createTime" | tail -n +11 | xargs -r gcloud app versions delete --quiet
popd > /dev/null

# auto_submit
pushd auto_submit > /dev/null
gcloud app deploy --project "$1" --version "version-$2" -q "$3" --no-stop-previous-version
gcloud app services set-traffic default --splits version-$2=1 --quiet
gcloud app versions list --format="value(version.id)" --sort-by="~version.createTime" | tail -n +11 | xargs -r gcloud app versions delete --quiet
popd > /dev/null
