#!/bin/bash
set -e

# Starts a Cocoon agent.

USER_NAME="flutter"
CONFIG_FILE="config.yaml"

if [ "$(whoami)" != "$USER_NAME" ]; then
  echo "Should run under user '$USER_NAME'."
  exit 1
fi

pushd "$HOME/cocoon/agent"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Unable to find $CONFIG_FILE."
  exit 1
fi

# Unlocks the login keychain, otherwise the error of "Your session has expired" occurs shortly.
if [ "$(uname)" == "Darwin" ]; then
  security unlock-keychain login.keychain
fi

pub get

dart bin/agent.dart ci -c "$CONFIG_FILE" 2>&1 >> "$HOME/agent.log" & disown

tail -f "$HOME/agent.log"

popd
