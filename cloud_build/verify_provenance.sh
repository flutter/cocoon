#!/bin/bash
# Copyright 2023 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script is used to verify provenance of our artifacts using slsa-verifier.
# If slsa-verifier is unable to ensure the provenance of the artifact is
# legitimate, then the script will exit with a non-zero exit code.
PROVENANCE_PATH=$1
BUILDER_ID=https://cloudbuild.googleapis.com/GoogleHostedWorker@v0.3
SOURCE_URI=https://github.com/flutter/cocoon

# Download the jq binary in order to obtain the artifact registry url from the
# docker image provenance.
echo "Installing jq using apt..."
apt update && apt install jq -y

# Download slsa-verifier in order to validate the docker image provenance.
# This takes the version of slsa-verifier defined in tooling/go.mod.
echo "Installing slsa-verifier using go..."
pushd tooling
go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier
popd

FULLY_QUALIFIED_DIGEST=$(cat $PROVENANCE_PATH |
  jq -r .image_summary.fully_qualified_digest)

# This command uses slsa-verifier to ensure the provenance has the correct
# source location and builder.
# "source-uri" is the original location of the source code
# "builder-id" is where the artifact was built (Note: GoogleHostedWorker is
# a GCP Cloud Build instance)
#
# Note: jq is used in order to obtain the full artifact registry url from
# the provenance metadata.
echo "Verifying the provenance is valid and correct..."
echo "Checking for source-uri of $SOURCE_URI"
slsa-verifier verify-image $FULLY_QUALIFIED_DIGEST \
  --source-uri $SOURCE_URI \
  --builder-id=$BUILDER_ID \
  --provenance-path $PROVENANCE_PATH

# If the provenance failed, try again, but check for 'git+' in the source-uri
# Context: Cloud Build is sometimes generating provenance with 'git+', but it
# will eventually be generated for all builds.
# TODO(drewroengoogle): Once the cloud build change is completely rolled out,
# remove this logic and only check for 'git+'.
COMMAND_RESULT=$?
if [[ $COMMAND_RESULT -eq 0 ]]; then
  echo "Provenance verified!" && exit $COMMAND_RESULT
fi

echo "Verifying the provenance is valid and correct..."
echo "Checking for source-uri of git+$SOURCE_URI"
slsa-verifier verify-image $FULLY_QUALIFIED_DIGEST \
  --source-uri git+$SOURCE_URI \
  --builder-id=$BUILDER_ID \
  --provenance-path $PROVENANCE_PATH

COMMAND_RESULT=$?
if [[ $COMMAND_RESULT -eq 0 ]]; then
  echo "Provenance verified!" && exit $COMMAND_RESULT
fi

echo "Failed to validate provenance." && exit $COMMAND_RESULT
