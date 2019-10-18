#!/bin/bash
# Runs a smoke test.
#
# This is useful to validate the runtime requirements of a Cocoon agent. It's intended to run
# manually after provision.
#
# Expectes current directory to be cocoon/agent.
set -e

LOG_FILE=$(mktemp)

case "$1" in
  ios)
    security unlock-keychain login.keychain
    dart bin/agent.dart run -r HEAD -t flutter_gallery_ios__start_up 2>&1 | tee "$LOG_FILE"
  ;;

  ios32)
    security unlock-keychain login.keychain
    dart bin/agent.dart run -r HEAD -t flutter_gallery_ios32__start_up 2>&1 | tee "$LOG_FILE"
  ;;

  android)
    dart bin/agent.dart run -r HEAD -t flutter_gallery__start_up 2>&1 | tee "$LOG_FILE"
  ;;

  *)
    echo "Usage: .bin/smoke_test.sh (ios | ios32 | android)"
    exit 1
  ;;
esac

echo "Please see logs at $LOG_FILE"
