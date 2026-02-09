# Specification: Implement get presubmit guard api

## Overview
This track involves implementing a new backend API endpoint in the `app_dart` service to serve real-time presubmit check statuses (based on the `PresubmitGuard` entity) to the Cocoon dashboard. The dashboard needs to display the progress and results of various validation stages for active pull requests to provide developers with actionable visibility into their PR health.

## User Stories
As a Flutter developer, I want to see the real-time status of my PR's presubmit checks on the Cocoon dashboard so that I can quickly identify and address failures without navigating through multiple GitHub or LUCI pages.

## Functional Requirements
1.  **New API Endpoint:** Create an authenticated GET endpoint in `app_dart` (e.g., `/api/get-presubmit-guard`).
2.  **Input Parameters:** The endpoint must accept a `slug` (e.g., `flutter/flutter`) and a `commit_sha` as query parameters.
3.  **Data Retrieval:** 
    - Query Cloud Firestore for all `PresubmitGuard` records matching the provided slug and commit SHA.
    - Note: There is a separate `PresubmitGuard` record for every stage (e.g., one for `fusion`, one for `engine`).
4.  **Response Format:** Return a single consolidated JSON object containing:
    - `pr_num`: The GitHub Pull Request Number (mapped from `pull_request_id` in Firestore).
    - `check_run_id`: The GitHub Check Run ID (shared across all stage records).
    - `author`: The GitHub handle of the PR author (shared across all stage records).
    - `stages`: A list of objects (one for each record found), each containing:
        - `name`: The name of the stage (e.g., `fusion` or `engine`).
        - `created_at`: The timestamp when the stage was created/started.
        - `builds`: A map where keys are `check_name` and values are of type `TaskStatus`.
        - **Sample `TaskStatus` values:** "Cancelled", "New", "In Progress", "Infra Failure", "Failed", "Succeeded", "Skipped".

## Non-Functional Requirements
- **Performance:** The endpoint should respond within 200ms for typical queries.
- **Reliability:** Handle cases where Firestore records may be partially populated or missing due to webhook latency. Consolidate metadata from the first available record.
- **Security:** Ensure the endpoint is protected by existing authentication mechanisms used for dashboard APIs.

## Acceptance Criteria
- [ ] A new GET endpoint exists in `app_dart` that accepts `slug` and `sha`.
- [ ] The endpoint correctly retrieves all matching `PresubmitGuard` records and consolidates them into a single response.
- [ ] The response includes the shared `pr_num`, `check_run_id`, `author`, and the list of individual stages with their build statuses.
- [ ] Unit tests in `app_dart` verify the consolidation logic with mocked Firestore data.
- [ ] The API documentation is updated to include this new endpoint.

## Out of Scope
- Implementing the frontend UI in the `dashboard/` package.
- Modifying the webhook ingestion logic (assuming `PresubmitGuard` is already being populated correctly).
- Support for historical/archived presubmit data (focus is on real-time).
