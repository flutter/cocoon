# Implementation Plan: Implement `getPresubmitGuardsForPullRequest` Request Handler

This plan outlines the steps to refactor `GuardStatus` logic and implement the `getPresubmitGuardsForPullRequest` request handler in `app_dart`.

## Phase 1: Refactor GuardStatus Logic
- [x] Task: Create failing tests for `GuardStatus.calculate` in `packages/cocoon_common`.
- [x] Task: Implement `GuardStatus.calculate` in `packages/cocoon_common/lib/guard_status.dart`.
- [x] Task: Update `GetPresubmitGuard` in `app_dart` to use the new `GuardStatus.calculate`.
- [x] Task: Verify existing tests for `GetPresubmitGuard` pass.
- [x] Task: Conductor - User Manual Verification 'Refactor GuardStatus Logic' (Protocol in workflow.md)

## Phase 2: Implement `GetPresubmitGuards` Handler
- [ ] Task: Create failing tests for `GetPresubmitGuards` in `app_dart/test/request_handlers/`.
- [ ] Task: Implement `GetPresubmitGuards` class in `app_dart/lib/src/request_handlers/get_presubmit_guards.dart`.
- [ ] Task: Register the new handler in `app_dart/bin/server.dart`.
- [ ] Task: Verify all tests pass and coverage is > 95%.
- [ ] Task: Conductor - User Manual Verification 'Implement GetPresubmitGuards Handler' (Protocol in workflow.md)
