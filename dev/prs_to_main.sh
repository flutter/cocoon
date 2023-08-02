#!/usr/bin/env bash
# Copyright 2019 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Run via ./prs_to_main.sh $GITHUB_USERNAME $GITHUB_TOKEN $REPOSITORY_NAME_WITH_OWNER
#
# To keep this script simple, you'll need to rerun this multiple times until it stops
# outputting PRs (indicating it processed all PRs)

GITHUB_ACTOR=$1
GITHUB_TOKEN=$2
GITHUB_REPOSITORY=$3
PREVIOUS_DEFAULT="master"
NEW_DEFAULT="main"
GITHUB_API_URL="https://api.github.com"

# Check all existing PRs to see if we should change their base
PRS=$(curl --silent -u $GITHUB_ACTOR:$GITHUB_TOKEN "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/pulls?base=$PREVIOUS_DEFAULT&state=open")

for row in $(echo $PRS | jq -r 'map(select(.locked == false)) | .[].url'); do
    echo "Attempting to update $row"
    curl --silent --show-error -w "Status Code: %{http_code}\n" --request PATCH --data '{"base": "'$NEW_DEFAULT'"}' -u $GITHUB_ACTOR:$GITHUB_TOKEN "$row"
done
