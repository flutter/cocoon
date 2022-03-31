#!/bin/bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Deploy a new auto submit version to google cloud.

# auto_submit
pushd auto_submit > /dev/null
gcloud app deploy --project "$1" --version "version-$2" -q "$3" --no-stop-previous-version
gcloud app services set-traffic auto-submit --splits version-$2=1 --quiet
gcloud app versions list --format="value(version.id)" --sort-by="~version.createTime"  --service=auto-submit | tail -n +20 | xargs -r gcloud app versions delete --quiet
popd > /dev/null
