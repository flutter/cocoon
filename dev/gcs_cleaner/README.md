# GCS Cleaner

Scrapes Flutter's Google Cloud Storage for artifacts that should no longer be
retained. Due to Flutter's release process uploading artifacts to the same place
as HEAD, we can't use a built in retention plan.

## Retention Policy

1. Never delete an artifact that was shipped in a release
   A. For any framework tag, we will retain the artifacts from the engine commit it shipped
2. Only retain artifacts from the past 6 months (subject to change)

## Overview

1. Generate the list of engine commits that were shipped in a release
   A. List all tags from flutter/flutter, and lookup their engine version
2. List all commits in gs://flutter_infra_release/flutter older than a year
3. Delete commit if not in (1)

## Permissions

Due to the infrequency this needs to run, this is intended to be run on a
human workstation. Multi-party approval is required, which requires a Googler
to run.

GCP owners access is required, see go/flutter-aod.

## Running

```**sh**
dart bin cleaner.dart \
  --token=$(gcloud auth print-identity-token) \
  --framework=$HOME/flutter
  # --no-dryrun to implement retention policy
```
