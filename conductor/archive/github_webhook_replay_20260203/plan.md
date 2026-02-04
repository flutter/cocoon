# Implementation Plan - Github Webhook Replay API

## Phase 1: Request Handler Development [checkpoint: 3d53540]
- [x] Task: Implement `GithubWebhookReplay` handler
    - [x] Create `app_dart/test/request_handlers/github_webhook_replay_test.dart` with failing tests for authentication (unauthenticated/unauthorized) and missing `id` parameter.
    - [x] Implement the `GithubWebhookReplay` class in `app_dart/lib/src/request_handlers/github_webhook_replay.dart` with basic validation and authentication.
    - [x] Add tests for Firestore retrieval (mocking document not found and successful retrieval).
    - [x] Implement Firestore retrieval logic using `GithubWebhookMessage.metadata`.
    - [x] Add tests for successful replay via `GithubWebhook.publish` (mocking `GithubWebhook`).
    - [x] Implement the call to `githubWebhook.publish` and return its response.
    - [x] Verify unit test coverage for the new handler (>95%).
- [x] Task: Conductor - User Manual Verification 'Phase 1: Request Handler Development' (Protocol in workflow.md)

## Phase 2: API Registration and Integration [checkpoint: 39a144c]
- [x] Task: Register the new endpoint in the server
    - [x] Modify `app_dart/lib/server.dart` to instantiate `GithubWebhookReplay` and register it at `/api/github-webhook-replay`.
    - [x] Verify that the `GithubWebhook` instance used for `/api/github-webhook-pullrequest` is passed to the new handler.
    - [x] (Optional) Add a simple integration test or server test to verify the route is correctly mapped.
- [x] Task: Conductor - User Manual Verification 'Phase 2: API Registration and Integration' (Protocol in workflow.md)
