# Implementation Plan: Unified Checkrun API and PresubmitCheck Model Update

This plan outlines the steps to add a `slug` field to the `PresubmitCheck` model, update the `GetPresubmitChecks` and `GetPresubmitGuard` APIs to use standardized `owner` and `repo` parameters, and update the Flutter dashboard to use these new APIs.

## Phase 1: Model Update (app_dart) [checkpoint: 3c65563]
In this phase, we update the `PresubmitCheck` model and the `UnifiedCheckRun` service to include the `slug` field.

- [x] Task: Update `PresubmitCheckId` in `app_dart/lib/src/model/firestore/presubmit_check.dart`
    - [x] Add `RepositorySlug slug` field.
    - [x] Update `documentId` to format: `owner_repo_checkRunId_buildName_attemptNumber`.
    - [x] Update `tryParse` to handle the new format.
- [x] Task: Update `PresubmitCheck` in `app_dart/lib/src/model/firestore/presubmit_check.dart`
    - [x] Add `fieldSlug` constant.
    - [x] Update factory constructors (`PresubmitCheck`, `PresubmitCheck.init`) to accept and store `slug`.
    - [x] Add `slug` getter.
- [x] Task: Update `UnifiedCheckRun` in `app_dart/lib/src/service/firestore/unified_check_run.dart`
    - [x] Update `initializeCiStagingDocument` to pass `slug` to `PresubmitCheck.init`.
    - [x] Update `reInitializeFailedChecks` to pass `slug` to `PresubmitCheck.init`.
    - [x] Update `_queryPresubmitChecks` to optionally filter by `slug`.
    - [x] Update `markConclusion` to handle the new `PresubmitCheckId` format (needs `slug` from `guardId`).
- [x] Task: Update `PresubmitCheck` tests
    - [x] Update `app_dart/test/model/firestore/presubmit_check_test.dart` to cover the new `slug` field and `documentId` format.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Model Update' (Protocol in workflow.md)

## Phase 2: Backend API Update (app_dart)
In this phase, we update the request handlers to use the standardized `owner` and `repo` parameters.

- [x] Task: Update `GetPresubmitChecks` in `app_dart/lib/src/request_handlers/get_presubmit_checks.dart`
    - [x] Add `kOwnerParam` and `kRepoParam`.
    - [x] Update `get` method to parse these parameters (default `owner` to 'flutter').
    - [x] Update call to `UnifiedCheckRun.getPresubmitCheckDetails` to include `slug` if possible (may need to update `getPresubmitCheckDetails` signature).
- [x] Task: Update `GetPresubmitGuard` in `app_dart/lib/src/request_handlers/get_presubmit_guard.dart`
    - [x] Replace `kSlugParam` with `kOwnerParam` and `kRepoParam`.
    - [x] Update `get` method to parse `owner` and `repo` and construct a `RepositorySlug`.
- [x] Task: Update Backend API tests
    - [x] Update `app_dart/test/request_handlers/get_presubmit_checks_test.dart`.
    - [x] Update `app_dart/test/request_handlers/get_presubmit_guard_test.dart`.

- [ ] Task: Conductor - User Manual Verification 'Phase 2: Backend API Update' (Protocol in workflow.md)

## Phase 3: Frontend Update (dashboard) [checkpoint: 54a4a82]
In this phase, we update the dashboard service and state to use the new API signatures.

- [x] Task: Update `AppEngineCocoonService` in `dashboard/lib/service/appengine_cocoon.dart`
    - [x] Update `fetchPresubmitGuard` to pass `owner` and `repo` instead of `slug`.
    - [x] Update `fetchPresubmitCheckDetails` to pass `owner` and `repo`.
- [x] Task: Update `PresubmitState` in `dashboard/lib/state/presubmit.dart`
    - [x] Ensure `fetchCheckDetails` and `fetchGuardStatus` pass the required parameters.
- [x] Task: Update Frontend tests
    - [x] Locate and update relevant tests in `dashboard/test/`.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Frontend Update' (Protocol in workflow.md)

## Phase 4: Final Verification [checkpoint: 3929fd6]
- [x] Task: Run all tests and verify full integration.
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Final Verification' (Protocol in workflow.md)
