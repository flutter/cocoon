#!/bin/bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Deploy latest cron jobs to google cloud.
# This includes cron jobs for both app_dart and auto_submit.

gcloud app deploy --project "$1" cron.yaml
