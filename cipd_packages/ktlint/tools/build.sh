#!/usr/bin/env bash
# Copyright 2019 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Script to build a self contained ruby cipd packages.

set -e
set -x

# Get the directory of this script.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get versions from config files.
KTLINT_MAJOR_VERSION=$(cat $DIR/../ktlint_metadata.txt | cut -d ',' -f 1)
KTLINT_FILE_NAME=$(cat $DIR/../ktlint_metadata.txt | cut -d ',' -f 2)

# Install brew dependencies
brew install curl

