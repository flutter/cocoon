#!/bin/bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Deploy a new auto_submit to cloud run

set -e
gcloud run deploy auto-submit --source auto_submit --project "$1" --region us-west2 --allow-unauthenticated
