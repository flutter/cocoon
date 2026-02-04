# Specification - Github Webhook Replay API

## Overview
Add a new API endpoint `/api/github-webhook-replay` to the Cocoon backend (`app_dart`). This endpoint will allow authenticated `@google.com` users to manually re-publish a previously received GitHub webhook message to Pub/Sub by retrieving it from Firestore and calling the `publish` method of the existing `GithubWebhook` handler.

## Functional Requirements
1.  **New Request Handler**: Create a new class `GithubWebhookReplay` in `app_dart/lib/src/request_handlers/github_webhook_replay.dart`.
    *   It must extend `ApiRequestHandler`.
    *   It must require `Config`, `AuthenticationProvider`, `FirestoreService`, and the `GithubWebhook` handler instance in its constructor.
2.  **API Endpoint**: Register the new handler at `/api/github-webhook-replay` in `app_dart/lib/server.dart`.
3.  **Authentication**: The handler must use the `DashboardAuthentication` provider (passed via `server.dart`) to ensure the user is authenticated and belongs to the `@google.com` domain.
4.  **Query Parameter**: The API will accept a `id` query parameter (e.g., `/api/github-webhook-replay?id=67ZoF8emsDqhgFjHkNdh`).
5.  **Firestore Retrieval**:
    *   Retrieve the `GithubWebhookMessage` document from Firestore collection `github_webhook_messages` using the provided `id`.
    *   If the document is not found, return a `404 Not Found` response.
6.  **Re-publication**:
    *   Extract the `event` and `jsonString` from the retrieved `GithubWebhookMessage`.
    *   Call `githubWebhook.publish(event, jsonString)` on the injected `GithubWebhook` instance.
7.  **Response**:
    *   Return the `Response` returned by the `githubWebhook.publish` call.

## Non-Functional Requirements
- **Security**: Access must be strictly restricted to authenticated `@google.com` users or allowed accounts.
- **Observability**: Log the replay action, including the document ID and the email of the user who triggered it.

## Acceptance Criteria
1.  A GET request to `/api/github-webhook-replay?id=<VALID_ID>` with a valid `@google.com` identity token results in the message being re-published.
2.  A request missing the `id` parameter returns a `400 Bad Request`.
3.  A request with a non-existent `id` returns a `404 Not Found`.
4.  An unauthorized user (non-@google.com and not in allowed accounts) returns a `403 Forbidden`.
5.  An unauthenticated request returns a `401 Unauthenticated`.

## Out of Scope
- A frontend UI for triggering this API.
- Bulk replay of multiple messages.
