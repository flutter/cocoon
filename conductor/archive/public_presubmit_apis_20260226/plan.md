# Implementation Plan: Public Presubmit APIs

This plan outlines the steps to refactor the request handler hierarchy and expose specific presubmit APIs publicly.

## Phase 1: Refactor Request Handler Hierarchy [checkpoint: 2a49e7e]
This phase focuses on introducing the `PublicApiRequestHandler` and refactoring `ApiRequestHandler` to inherit from it.

- [x] Task: Create `PublicApiRequestHandler`
    - [x] Create `app_dart/lib/src/request_handling/public_api_request_handler.dart`.
    - [x] Move `checkRequiredParameters` and `checkRequiredQueryParameters` from `ApiRequestHandler` to `PublicApiRequestHandler`.
- [x] Task: Refactor `ApiRequestHandler`
    - [x] Update `app_dart/lib/src/request_handling/api_request_handler.dart` to extend `PublicApiRequestHandler`.
    - [x] Remove the moved methods from `ApiRequestHandler`.
- [x] Task: Verify Base Class Refactoring
    - [x] Run existing tests for `ApiRequestHandler` and `RequestHandler` to ensure no regressions.
    - [x] Command: `dart test app_dart/test/request_handling/api_request_handler_test.dart`
- [x] Task: Conductor - User Manual Verification 'Phase 1: Refactor Request Handler Hierarchy' (Protocol in workflow.md)


## Phase 2: Expose Target APIs Publicly [checkpoint: 4c366bf]
This phase transitions the specified handlers to `PublicApiRequestHandler`.

- [x] Task: Refactor `GetPresubmitChecks`
    - [x] Update `app_dart/lib/src/request_handlers/get_presubmit_checks.dart` to extend `PublicApiRequestHandler`.
    - [x] Remove `authenticationProvider` from the constructor and `super` call.
    - [x] Update tests in `app_dart/test/request_handlers/get_presubmit_checks_test.dart` to reflect constructor changes.
- [x] Task: Refactor `GetPresubmitGuardSummaries`
    - [x] Update `app_dart/lib/src/request_handlers/get_presubmit_guard_summaries.dart` to extend `PublicApiRequestHandler`.
    - [x] Remove `authenticationProvider` from the constructor and `super` call.
    - [x] Update tests in `app_dart/test/request_handlers/get_presubmit_guard_summaries_test.dart` to reflect constructor changes.
- [x] Task: Refactor `GetPresubmitGuard`
    - [x] Update `app_dart/lib/src/request_handlers/get_presubmit_guard.dart` to extend `PublicApiRequestHandler`.
    - [x] Remove `authenticationProvider` from the constructor and `super` call.
    - [x] Update tests in `app_dart/test/request_handlers/get_presubmit_guard_test.dart` to reflect constructor changes.
- [x] Task: Verify Public Access
    - [x] Add/Update tests for each handler to verify they return successful responses even when no authentication is provided.
- [x] Task: Update API Paths
    - [x] Change `/api/get-presubmit-*` to `/api/public/get-presubmit-*` in `app_dart/lib/server.dart`.
- [x] Task: Refactor all Public Handlers
    - [x] Identify all handlers with `/api/public/` path.
    - [x] Update `GetBuildStatus`, `GetSuppressedTests`, `GetRepos`, `GetEngineArtifactsReady`, `GetReleaseBranches`, `GetStatus`, `GetGreenCommits`, and `GithubRateLimitStatus` to extend `PublicApiRequestHandler`.
    - [x] Verify all request handler tests pass.
- [x] Task: Update Dashboard API Paths
    - [x] Update `dashboard/lib/service/appengine_cocoon.dart` to use `/api/public/` for presubmit endpoints.
    - [x] Update `dashboard/test/service/presubmit_service_test.dart` to verify new paths.
- [x] Task: Conductor - User Manual Verification 'Phase 2: Expose Target APIs Publicly' (Protocol in workflow.md)


## Phase 3: Quality Assurance & Cleanup [checkpoint: 482376b]
Final checks for code quality and standards.

- [x] Task: Run Code Quality Checks
    - [x] Execute `dart format --set-exit-if-changed .` in `app_dart`.
    - [x] Execute `dart analyze --fatal-infos .` in `app_dart`.
- [x] Task: Final Test Suite Execution
    - [x] Run all tests in `app_dart` to ensure overall system stability.
    - [x] Command: `dart test app_dart/test`
- [x] Task: Conductor - User Manual Verification 'Phase 3: Quality Assurance & Cleanup' (Protocol in workflow.md)

