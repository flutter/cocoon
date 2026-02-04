# Implementation Plan: Implement get presubmit guard api

## Phase 1: Infrastructure & Data Model
Establish the data structures and service interfaces required to interact with Firestore for `PresubmitGuard` records.

- [ ] Task: Define `PresubmitGuard` Model and DTOs
    - [ ] Create/Update the Firestore model for `PresubmitGuard` if not already present in `app_dart/lib/src/model/firestore/`.
    - [ ] Create a `GetPresubmitGuardResponse` DTO to match the specified API response format (pr_num, check_run_id, author, stages).
- [ ] Task: Create Firestore Service Method
    - [ ] Implement a method in the Firestore service (e.g., `app_dart/lib/src/service/firestore.dart`) to query `PresubmitGuard` records by `slug` and `commit_sha`.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Infrastructure & Data Model' (Protocol in workflow.md)

## Phase 2: API Endpoint Implementation
Implement the request handler and wire it into the `app_dart` server.

- [ ] Task: Implement `GetPresubmitGuard` Request Handler
    - [ ] Create a new request handler class in `app_dart/lib/src/request_handlers/`.
    - [ ] Implement logic to:
        - Extract `slug` and `sha` from query parameters.
        - Call the Firestore service to retrieve records.
        - Consolidate records into the `GetPresubmitGuardResponse` format.
        - Handle cases with no matching records (e.g., return 404 or empty response).
- [ ] Task: Register Endpoint in Server
    - [ ] Add the new `/api/get-presubmit-guard` route to the `app_dart` server configuration (e.g., `app_dart/lib/src/server.dart` or equivalent).
- [ ] Task: Conductor - User Manual Verification 'Phase 2: API Endpoint Implementation' (Protocol in workflow.md)

## Phase 3: Verification & Documentation
Ensure the feature is robust, tested, and documented.

- [ ] Task: Write Unit Tests for Request Handler
    - [ ] Implement tests in `app_dart/test/request_handlers/` using mocked Firestore service.
    - [ ] Verify consolidation logic for multiple stages.
    - [ ] Verify mapping of `pull_request_id` to `pr_num`.
- [ ] Task: Update API Documentation
    - [ ] Document the new endpoint in the project's API docs or README.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Verification & Documentation' (Protocol in workflow.md)
