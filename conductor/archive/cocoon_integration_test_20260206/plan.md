# Implementation Plan: Cocoon Integration Test [checkpoint: 5d0d05c]

## Phase 1: Package Setup & Fake Consolidation
- [x] Task: Create `packages/cocoon_integration_test` structure.
    - [x] Create directory and `pubspec.yaml`.
    - [x] Add dependencies: `cocoon_service` (app_dart), `cocoon_server_test`, `test`, `http`, etc.
- [x] Task: Consolidate Fakes into `packages/cocoon_integration_test`.
    - [x] Identify `FakeConfig`, `FakeDashboardAuthentication`, `FakeBuildBucketClient`, `FakeLuciBuildService`, `FakeGerritService`, `FakeScheduler`, `FakeCiYamlFetcher`, `FakeBuildStatusService`, `FakeContentAwareHashService`.
    - [x] Move these from `app_dart/test/src/` (or wherever they are) to `packages/cocoon_integration_test/lib/src/fakes/`.
    - [x] Export them from `packages/cocoon_integration_test/lib/testing.dart`.
    - [x] Update `app_dart` to depend on `cocoon_integration_test` for these fakes (refactor existing tests).

## Phase 2: Implementation of Integration Server
- [x] Task: Implement `IntegrationServer` class.
    - [x] Create `packages/cocoon_integration_test/lib/src/server.dart`.
    - [x] Implement `startServer({Config? config, ...})` which sets up the `CocoonService` (from `app_dart`) with the Fakes.
    - [x] Ensure `CacheService` is `inMemory: true`.
- [x] Task: Implement Test Helpers.
    - [x] Create helper methods to seed the Fakes (e.g., `populateFirestore`, `setConfigs`).

## Phase 3: Verification
- [x] Task: Write a "Smoke Test".
    - [x] Create `packages/cocoon_integration_test/test/server_test.dart`.
    - [x] Verify the server starts and responds to a simple health check or API call.
- [x] Task: Conductor - User Manual Verification (Protocol in workflow.md)
