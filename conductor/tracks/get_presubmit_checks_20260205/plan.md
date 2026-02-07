# Implementation Plan: Presubmit Check Details API

## Phase 1: RPC Models
- [x] Task: Create `PresubmitCheck` RPC model
    - [x] Create `packages/cocoon_common/lib/src/rpc_model/presubmit_check.dart`
    - [x] Define `PresubmitCheck` with `JsonSerializable` and fields: `attemptNumber`, `taskName`, `creationTime`, `startTime`, `endTime`, `status`, `summary`
    - [x] Export in `packages/cocoon_common/lib/rpc_model.dart`
- [x] Task: Generate JSON serialization code
    - [x] `dart run build_runner build` in `packages/cocoon_common`
- [x] Task: Conductor - User Manual Verification 'Phase 1: RPC Models' (Protocol in workflow.md)

## Phase 2: Backend Logic & API Handler
- [x] Task: Update `UnifiedCheckRun` with retrieval method
    - [x] Add `static Future<List<PresubmitCheck>> getPresubmitCheckDetails(...)` to `app_dart/lib/src/service/firestore/unified_check_run.dart`
    - [x] Ensure it uses the existing `_queryPresubmitChecks` method
- [x] Task: Create `GetPresubmitChecks` RequestHandler
    - [x] Create `app_dart/lib/src/request_handlers/get_presubmit_checks.dart`
    - [x] Implement parameter validation (mandatory `check_run_id`, `build_name`)
    - [x] Use `UnifiedCheckRun.getPresubmitCheckDetails` to fetch data
    - [x] Map Firestore models to RPC models and sort by `attemptNumber` ascending
    - [x] Return top-level JSON array
- [x] Task: Conductor - User Manual Verification 'Phase 2: Backend Logic & API Handler' (Protocol in workflow.md)

## Phase 3: Registration & Integration
- [x] Task: Register handler in `app_dart/lib/server.dart`
- [x] Task: Conductor - User Manual Verification 'Phase 3: Registration & Integration' (Protocol in workflow.md)

## Phase 4: Quality Assurance
- [x] Task: Write unit tests
    - [x] Create `app_dart/test/request_handlers/get_presubmit_checks_test.dart`
    - [x] Test success and error cases (400, 404)
- [x] Task: Conductor - User Manual Verification 'Phase 4: Quality Assurance' (Protocol in workflow.md)
