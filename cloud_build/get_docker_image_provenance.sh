#!/usr/bin/env bash
# Copyright 2023 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script is used to pull a docker image's provenance and save it to a file.
DOCKER_IMAGE_URL=$1
OUTPUT_DIRECTORY=$2
# Getting the docker image provenance can be flaky due to the provenance not
# uploading fast enough, or a transient error from artifact registry, so retry
# up to 3 times.
MAX_ATTEMPTS=3

# Download the jq binary in order to obtain the artifact registry url from the
# docker image provenance.
echo "Installing jq using apt..."
apt update && apt install jq -y

for attempt in $(seq 1 $MAX_ATTEMPTS)
do
    echo "(Attempt $attempt) Obtaining provenance for $1"
    gcloud artifacts docker images describe \
	    $DOCKER_IMAGE_URL --show-provenance --format json > $OUTPUT_DIRECTORY
    COMMAND_RESULT=$?
    if [[ $COMMAND_RESULT -eq 0 ]]
    then
        echo "Successfully obtained provenance and saved to $2"
        break
    else
        echo "Failed to obtain provenance."
        sleep 30
    fi
done

if [[ $COMMAND_RESULT -ne 0 ]]
then
  echo "Failed to download provenance." && exit $COMMAND_RESULT
fi
