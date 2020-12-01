#!/bin/bash                                                                      
# Copyright 2020 The Flutter Authors. All rights reserved.                       
# Use of this source code is governed by a BSD-style license that can be         
# found in the LICENSE file.

set -e

function script_location() {
  local script_location="${BASH_SOURCE[0]}"
  # Resolve symlinks
  while [[ -h "$script_location" ]]; do
    DIR="$(cd -P "$(dirname "$script_location")" >/dev/null && pwd)"
    script_location="$(readlink "$script_location")"
    [[ "$script_location" != /* ]] && script_location="$DIR/$script_location"
  done
  echo "$(cd -P "$(dirname "$script_location")" >/dev/null && pwd)"
}

# So that users can run this script locally from any directory and it will work as
# expected.
SCRIPT_LOCATION="$(script_location)"
cd "$SCRIPT_LOCATION"
./device_doctor $@
