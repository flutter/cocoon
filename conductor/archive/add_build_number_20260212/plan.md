# Implementation Plan: Add `buildNumber` to `PresubmitJob`

This plan outlines the steps to add an optional `buildNumber` field across the Cocoon backend models and ensure it is populated during the check run completion process.

## Phase 1: Model Updates [checkpoint: 539f12a]

This phase focuses on updating the internal and external data models to support the new `buildNumber` field.

- [x] Task: Update `PresubmitJobState` Model
    - [x] Add `int? buildNumber` to `PresubmitJobState` class in `app_dart/lib/src/model/common/presubmit_job_state.dart`.
    - [x] Update `BuildToPresubmitJobState` extension to map `number` from `bbv2.Build` to `buildNumber`.
    - [x] Update existing tests to reflect constructor changes.
- [x] Task: Update `PresubmitJob` Firestore Model
    - [x] Add `fieldBuildNumber` constant and `buildNumber` getter/setter to `PresubmitJob` in `app_dart/lib/src/model/firestore/presubmit_job.dart`.
    - [x] Update `fromDocument`, `init`, and `toJson` (or equivalent) to handle the new field.
    - [x] Add unit tests for serialization/deserialization of `buildNumber`.
- [x] Task: Update `PresubmitJobResponse` RPC Model
    - [x] Add `int? buildNumber` to `PresubmitJobResponse` in `packages/cocoon_common/lib/src/rpc_model/presubmit_job_response.dart`.
    - [x] Run `dart run build_runner build --delete-conflicting-outputs` in `packages/cocoon_common/` to regenerate JSON serialization code.
    - [x] Add unit tests for the RPC model.
- [x] Task: Conductor - User Manual Verification 'Model Updates' (Protocol in workflow.md)

## Phase 2: Backend Logic and API Updates [checkpoint: ead405d]

This phase integrates the new field into the core logic and ensures it is returned by the API.

- [x] Task: Update `UnifiedCheckRun.markConclusion` Logic
    - [x] Update `markConclusion` in `app_dart/lib/src/service/firestore/unified_check_run.dart` to assign `state.buildNumber` to `presubmitJob.buildNumber`.
    - [x] Add/update tests in `app_dart/test/service/firestore/unified_check_run_test.dart` to verify the build number is correctly saved to Firestore.
- [x] Task: Update `GetPresubmitJobs` API Handler
    - [x] Update `GetPresubmitJobs` in `app_dart/lib/src/request_handlers/get_presubmit_jobs.dart` to map `PresubmitJob.buildNumber` to `PresubmitJobResponse.buildNumber`.
    - [x] Update handler tests to verify the API response contains the build number.
- [x] Task: Conductor - User Manual Verification 'Backend Logic and API Updates' (Protocol in workflow.md)
