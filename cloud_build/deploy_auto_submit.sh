#!/usr/bin/env bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Deploy a new auto submit version to google cloud.

pushd auto_submit > /dev/null
# auto_submit
gcloud app deploy --project "$1" --version "version-$2" -q --no-promote --no-stop-previous-version --image-url "us-docker.pkg.dev/$1/appengine/auto-submit.version-$2"
gcloud app services set-traffic auto-submit --splits version-$2=1 --quiet
# Google Cloud quota only allows 30 versions.
# For daily builds, this will keep the 10 most recent versions, but wipe the rest.
gcloud app versions list --format="value(version.id)" --sort-by="~version.createTime"  --service=auto-submit | tail -n +20 | xargs -r gcloud app versions delete --quiet
popd > /dev/null
