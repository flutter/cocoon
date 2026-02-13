# Implementation Plan: Add `buildNumber` to `PresubmitCheck`

This plan outlines the steps to add an optional `buildNumber` field across the Cocoon backend models and ensure it is populated during the check run completion process.

## Phase 1: Model Updates

This phase focuses on updating the internal and external data models to support the new `buildNumber` field.

- [x] Task: Update `PresubmitCheckState` Model
    - [ ] Add `int? buildNumber` to `PresubmitCheckState` class in `app_dart/lib/src/model/common/presubmit_check_state.dart`.
    - [ ] Update `BuildToPresubmitCheckState` extension to map `number` from `bbv2.Build` to `buildNumber`.
    - [ ] Update existing tests to reflect constructor changes.
- [ ] Task: Update `PresubmitCheck` Firestore Model
    - [ ] Add `fieldBuildNumber` constant and `buildNumber` getter/setter to `PresubmitCheck` in `app_dart/lib/src/model/firestore/presubmit_check.dart`.
    - [ ] Update `fromDocument`, `init`, and `toJson` (or equivalent) to handle the new field.
    - [ ] Add unit tests for serialization/deserialization of `buildNumber`.
- [ ] Task: Update `PresubmitCheckResponse` RPC Model
    - [ ] Add `int? buildNumber` to `PresubmitCheckResponse` in `packages/cocoon_common/lib/src/rpc_model/presubmit_check_response.dart`.
    - [ ] Run `dart run build_runner build --delete-conflicting-outputs` in `packages/cocoon_common/` to regenerate JSON serialization code.
    - [ ] Add unit tests for the RPC model.
- [ ] Task: Conductor - User Manual Verification 'Model Updates' (Protocol in workflow.md)

## Phase 2: Backend Logic and API Updates

This phase integrates the new field into the core logic and ensures it is returned by the API.

- [ ] Task: Update `UnifiedCheckRun.markConclusion` Logic
    - [ ] Update `markConclusion` in `app_dart/lib/src/service/firestore/unified_check_run.dart` to assign `state.buildNumber` to `presubmitCheck.buildNumber`.
    - [ ] Add/update tests in `app_dart/test/service/firestore/unified_check_run_test.dart` to verify the build number is correctly saved to Firestore.
- [ ] Task: Update `GetPresubmitChecks` API Handler
    - [ ] Update `GetPresubmitChecks` in `app_dart/lib/src/request_handlers/get_presubmit_checks.dart` to map `PresubmitCheck.buildNumber` to `PresubmitCheckResponse.buildNumber`.
    - [ ] Update handler tests to verify the API response contains the build number.
- [ ] Task: Conductor - User Manual Verification 'Backend Logic and API Updates' (Protocol in workflow.md)
