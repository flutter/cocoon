# Implementation Plan: Merge Queue Hooks API

## Phase 1: Request Handler Implementation
- [x] Task: Create `MergeQueueHooks` request handler skeleton and failing tests.
    - [x] Create `app_dart/lib/src/request_handlers/merge_queue_hooks.dart` with a basic `ApiRequestHandler` implementation.
    - [x] Create `app_dart/test/request_handlers/merge_queue_hooks_test.dart`.
    - [x] Write failing tests for authorization (non-google email) and basic GET request.
- [x] Task: Implement authorization and Firestore query logic using `FirestoreService`.
    - [x] Add email domain check in `MergeQueueHooks`.
    - [x] Implement Firestore query using `FirestoreService` to fetch latest 20 `GithubWebhookMessage` documents sorted by timestamp.
    - [x] Update tests to mock `FirestoreService` and verify query parameters.
- [x] Task: Implement JSON parsing and response formatting.
    - [x] Add logic to parse `jsonString` from each message and extract required fields (`action`, `head_ref`, `head_commit_id`, `head_commit_message`).
    - [x] Format the response as a JSON array.
    - [x] Update tests to verify the content of the JSON response.
- [x] Task: Create RPC models for the response.
    - [x] Create `MergeGroupHooks` and `MergeGroupHook` in `packages/cocoon_common/lib/src/rpc_model/merge_group_hooks.dart`.
    - [x] Export the models in `packages/cocoon_common/lib/rpc_model.dart`.
    - [x] Use the models in `MergeQueueHooks`.
- [x] Task: Register the new handler in `server.dart`.
    - [x] Add `/api/merge_queue_hooks` route to `createServer` in `app_dart/lib/server.dart`.
    - [x] Verify the endpoint is reachable in an integration-like test if feasible.
- [x] Task: Conductor - User Manual Verification 'Phase 1: Request Handler Implementation' (Protocol in workflow.md)