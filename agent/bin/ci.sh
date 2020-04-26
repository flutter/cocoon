#!/bin/bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Starts a Cocoon agent to run in continuous integration (CI) mode.
#
# Expectes the current directory to be cocoon/agent.
# Requires $HOME environment variable.
set -e

USER_NAME="flutter"
CONFIG_FILE="config.yaml"
LOG_FILE="$HOME/agent.log"

pid="$(pgrep -f bin/agent.dart)" || true

if [[ ! -z "$pid" ]]; then
  echo "The agent is already running with PID: $pid."
  exit 1
fi

if [[ "$(whoami)" != "$USER_NAME" ]]; then
  echo "Should run under user: $USER_NAME."
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Unable to find $CONFIG_FILE."
  exit 1
fi

# Unlocks the login keychain, otherwise Xcode build reports the error of "Your session has expired"
# shortly.
if [[ "$(uname)" == "Darwin" ]]; then
  security unlock-keychain login.keychain
fi

pub get

dart bin/agent.dart ci -c "$CONFIG_FILE" >> "$LOG_FILE" 2>&1 & disown

pid="$(pgrep -f bin/agent.dart)" || true

if [[ -z "$pid" ]]; then
  echo "Unable to start the agent, please check the log at $LOG_FILE"
else
  echo "Started the agent with PID: $pid."
fi
