# Specification: Merge Queue Hooks API

## Overview
Add a new API endpoint `/api/merge_queue_hooks` to the `app_dart` service. This endpoint will allow authorized users (with `@google.com` emails) to query the most recent GitHub webhook messages related to merge queues stored in Firestore.

## Functional Requirements
1.  **Endpoint:** `GET /api/merge_queue_hooks`
2.  **Authentication & Authorization:**
    *   Implement using `ApiRequestHandler`.
    *   Verify that the authenticated user's email ends with `@google.com`.
    *   If the email does not match, return a `403 Forbidden` response.
3.  **Data Retrieval:**
    *   Use the internal `FirestoreService` to query the Firestore collection.
    *   Query the Firestore collection defined by `GithubWebhookMessage.metadata.collectionId` (i.e., `github_webhook_messages`).
    *   Sort results by the `timestamp` field in descending order.
    *   Limit the query to the latest 20 documents.
4.  **Response Format:**
    *   Return a JSON array of objects.
    *   Each object must include:
        *   `timestamp`: The timestamp from the Firestore document.
        *   `action`: Extracted from the `jsonString` payload.
        *   `head_ref`: Extracted from `jsonString.merge_group.head_ref`.
        *   `head_commit_id`: Extracted from `jsonString.merge_group.head_commit.id`.
        *   `head_commit_message`: The first line of the message extracted from `jsonString.merge_group.head_commit.message`.

## Non-Functional Requirements
*   Adhere to existing `app_dart` request handling patterns.
*   Ensure efficient Firestore querying.
*   Maintain >95% code coverage for the new handler.

## Acceptance Criteria
*   An authorized Google user can successfully retrieve the last 20 merge queue hooks.
*   A non-Google authenticated user receives a `403 Forbidden`.
*   An unauthenticated user receives a `401 Unauthorized`.
*   The JSON response contains all requested fields correctly parsed from the webhook payload.

## Out of Scope
*   Dynamic filtering or pagination via query parameters.
*   Support for webhook events other than those stored in `github_webhook_messages`.
