#!/bin/bash
set -e

# Runs a smoke test in order to validate the runtime environment for Cocoon agent.

LOG=$(mktemp)

case "$1" in
  ios)
    security unlock-keychain login.keychain
    dart bin/agent.dart run -r HEAD -t flutter_gallery_ios__start_up | tee $LOG
  ;;

  ios32)
    security unlock-keychain login.keychain
    dart bin/agent.dart run -r HEAD -t flutter_gallery_ios32__start_up | tee $LOG
  ;;

  android)
    dart bin/agent.dart run -r HEAD -t flutter_gallery__start_up | tee $LOG
  ;;

  *)
    echo "Usage: ./smoke_test.sh (ios | ios32 | android)"
    exit 1
  ;;
esac

echo "See logs at $LOG"
