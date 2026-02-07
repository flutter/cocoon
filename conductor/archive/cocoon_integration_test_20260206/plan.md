# Implementation Plan: Cocoon Integration Test

## Phase 1: Package Setup & Fake Consolidation
- [ ] Task: Create `packages/cocoon_integration_test` structure.
    - [ ] Create directory and `pubspec.yaml`.
    - [ ] Add dependencies: `cocoon_service` (app_dart), `cocoon_server_test`, `test`, `http`, etc.
- [ ] Task: Consolidate Fakes into `packages/cocoon_server_test`.
    - [ ] Identify `FakeConfig`, `FakeDashboardAuthentication`, `FakeBuildBucketClient`, `FakeLuciBuildService`, `FakeGerritService`, `FakeScheduler`, `FakeCiYamlFetcher`, `FakeBuildStatusService`, `FakeContentAwareHashService`.
    - [ ] Move these from `app_dart/test/src/` (or wherever they are) to `packages/cocoon_server_test/lib/src/fakes/`.
    - [ ] Export them from `packages/cocoon_server_test/lib/testing.dart` (or similar).
    - [ ] Update `app_dart` to depend on `cocoon_server_test` for these fakes (refactor existing tests).
    - [ ] *Self-Correction:* If moving is too disruptive, copy them for now, but moving is better for maintenance. We will attempt to move/share.

## Phase 2: Implementation of Integration Server
- [ ] Task: Implement `IntegrationServer` class.
    - [ ] Create `packages/cocoon_integration_test/lib/src/server.dart`.
    - [ ] Implement `startServer({Config? config, ...})` which sets up the `CocoonService` (from `app_dart`) with the Fakes.
    - [ ] Ensure `CacheService` is `inMemory: true`.
- [ ] Task: Implement Test Helpers.
    - [ ] Create helper methods to seed the Fakes (e.g., `populateFirestore`, `setConfigs`).

## Phase 3: Verification
- [ ] Task: Write a "Smoke Test".
    - [ ] Create `packages/cocoon_integration_test/test/server_test.dart`.
    - [ ] Verify the server starts and responds to a simple health check or API call.
- [ ] Task: Conductor - User Manual Verification (Protocol in workflow.md)
