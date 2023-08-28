#!/usr/bin/env bash
# Copyright 2023 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script is used to pull a docker image's provenance and save it to a file.
DOCKER_IMAGE_URL=$1
OUTPUT_DIRECTORY=$2
# Getting the docker image provenance can be flaky, so retry up to 3 times.
MAX_ATTEMPTS=3

for attempt in $(seq 1 $MAX_ATTEMPTS)
do
    echo "(Attempt $attempt) Obtaining provenance for $1"

    #
    gcloud artifacts docker images describe \
	    $DOCKER_IMAGE_URL --show-provenance --format json > tmp.json
    COMMAND_RESULT=$?
    val=$(cat tmp.json | jq -r '.provenance_summary.provenance[0].envelope.payload' | base64 -d | jq '.predicate.recipe.arguments.sourceProvenance')
    cat tmp.json | jq ".provenance_summary.provenance[0].build.intotoStatement.slsaProvenance.recipe.arguments.sourceProvenance = ${val}" > $OUTPUT_DIRECTORY
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
