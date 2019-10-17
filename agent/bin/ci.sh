#!/bin/bash
# Starts a Cocoon agent to run in continuous integration (CI) mode.
#
# Expectes current directory to be cocoon/agent.
# Requires $HOME environment variable.
set -e

USER_NAME="flutter"
CONFIG_FILE="config.yaml"
LOG_FILE="$HOME/agent.log"

if [ "$(whoami)" != "$USER_NAME" ]; then
  echo "Should run under user: $USER_NAME."
  exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Unable to find $CONFIG_FILE."
  exit 1
fi

# Unlocks the login keychain, otherwise Xcode build reports the error of
# "Your session has expired" shortly.
if [ "$(uname)" == "Darwin" ]; then
  security unlock-keychain login.keychain
fi

pub get

dart bin/agent.dart ci -c "$CONFIG_FILE" 2>&1 >> "$LOG_FILE" &

pid="$(pgrep -f bin/agent.dart)" || true

if [ -z "$pid" ]; then
  echo "Unable to start agent, please check the log at $LOG_FILE"
else
  echo "Started agent with PID: $pid"
fi
