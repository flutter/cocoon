# Specification: Cocoon Integration Test

## Goal
Create a new package `packages/cocoon_integration_test` to facilitate offline integration testing of the Cocoon backend and frontend.

## Background
Currently, testing the Cocoon server (`app_dart`) involves unit tests or live integration tests. There is a need for a "fake server" environment that can run offline, simulating all external dependencies (GitHub, Gerrit, BuildBucket, etc.) with in-memory fakes. This will allow for robust, deterministic integration testing of the dashboard and other clients against a running (fake) server.

## Requirements
1.  **New Package:** `packages/cocoon_integration_test`.
2.  **Fake Server Factory:** Provide a method to start the `app_dart` server with injected fakes.
3.  **Fakes over Mocks:** Prefer using Fakes (functional implementations) over Mocks (record/replay) where possible.
4.  **Components to Fake:**
    -   `Config` (`FakeConfig` with `webhookKeyValue`)
    -   `CacheService` (In-memory)
    -   `Authentication` (`FakeDashboardAuthentication` for both standard and swarming)
    -   `BranchService`
    -   `BuildBucketClient`
    -   `LuciBuildService`
    -   `GithubChecksService`
    -   `CommitService`
    -   `GerritService`
    -   `Scheduler`
    -   `CiYamlFetcher`
    -   `BuildStatusService`
    -   `ContentAwareHashService`
5.  **External Dependencies:** The package should depend on `app_dart` (likely via path or git dependency if strict package separation isn't enforced yet, or by moving shared types to `cocoon_common`). *Note: For this iteration, we will assume `app_dart` is accessible.*

## Deliverables
-   `packages/cocoon_integration_test/pubspec.yaml`
-   `packages/cocoon_integration_test/lib/cocoon_integration_test.dart` (Entry point)
-   `packages/cocoon_integration_test/lib/src/server.dart` (Server setup logic)
-   Basic test to verify the fake server starts.
