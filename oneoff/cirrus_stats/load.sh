#!/bin/bash
set -e

# bq \
#   --project_id=flutter-dashboard \
#   load \
#   --replace=true \
#   --source_format=NEWLINE_DELIMITED_JSON \
#   --autodetect cirrus.Build \
#   ./tmp/build.json


bq \
  --project_id=flutter-dashboard \
  load \
  --replace=true \
  --source_format=NEWLINE_DELIMITED_JSON \
  --autodetect \
  cirrus.Task \
  ./tmp/task.json

