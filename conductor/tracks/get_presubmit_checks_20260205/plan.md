# Implementation Plan: Presubmit Check Details API

## Phase 1: RPC Models
- [ ] Task: Create `PresubmitCheck` RPC model
    - [ ] Create `packages/cocoon_common/lib/src/rpc_model/presubmit_check.dart`
    - [ ] Define `PresubmitCheck` with `JsonSerializable` and fields: `attemptNumber`, `taskName`, `creationTime`, `startTime`, `endTime`, `status`, `summary`
    - [ ] Export in `packages/cocoon_common/lib/rpc_model.dart`
- [ ] Task: Generate JSON serialization code
    - [ ] `dart run build_runner build` in `packages/cocoon_common`
- [ ] Task: Conductor - User Manual Verification 'Phase 1: RPC Models' (Protocol in workflow.md)

## Phase 2: Backend Logic & API Handler
- [ ] Task: Update `UnifiedCheckRun` with retrieval method
    - [ ] Add `static Future<List<PresubmitCheck>> getPresubmitCheckDetails(...)` to `app_dart/lib/src/service/firestore/unified_check_run.dart`
    - [ ] Ensure it uses the existing `_queryPresubmitChecks` method
- [ ] Task: Create `GetPresubmitChecks` RequestHandler
    - [ ] Create `app_dart/lib/src/request_handlers/get_presubmit_checks.dart`
    - [ ] Implement parameter validation (mandatory `check_run_id`, `check_name`)
    - [ ] Use `UnifiedCheckRun.getPresubmitCheckDetails` to fetch data
    - [ ] Map Firestore models to RPC models and sort by `attemptNumber` ascending
    - [ ] Return top-level JSON array
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Backend Logic & API Handler' (Protocol in workflow.md)

## Phase 3: Registration & Integration
- [ ] Task: Register handler in `app_dart/lib/server.dart`
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Registration & Integration' (Protocol in workflow.md)

## Phase 4: Quality Assurance
- [ ] Task: Write unit tests
    - [ ] Create `app_dart/test/request_handlers/get_presubmit_checks_test.dart`
    - [ ] Test success and error cases (400, 404)
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Quality Assurance' (Protocol in workflow.md)
