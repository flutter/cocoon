# Specification: Re-run Failed Jobs API for Unified Checkrun

## Overview
This track implements two new backend API endpoints in the `app_dart` service to allow users to re-run failed CI jobs directly from Cocoon:
1.  **Re-run Failed Job**: Triggers a re-run for a specific failed job.
2.  **Re-run All Failed Jobs**: Triggers a re-run for all currently failed jobs within a unified checkrun.

These APIs will facilitate direct control over CI job execution, reducing the need for developers to switch to GitHub or LUCI interfaces for common task recovery.

## Functional Requirements
1.  **Endpoint: `rerun_failed_job`**
    -   **Method**: `POST`
    -   **Parameters**:
        -   `check_run_id`: The ID of the GitHub Check Run.
        -   `build_bucket_id`: The ID of the BuildBucket build to re-run.
    -   **Behavior**: Triggers a re-run of the specified job via the LUCI BuildBucket API.

2.  **Endpoint: `rerun_all_failed_jobs`**
    -   **Method**: `POST`
    -   **Parameters**:
        -   `check_run_id`: The ID of the GitHub Check Run.
    -   **Behavior**: Identifies all failed jobs associated with the given Check Run and triggers re-runs for each via the LUCI BuildBucket API.

3.  **Authentication and Authorization**
    -   Requests must be authenticated.
    -   The authenticated user must have **Write Access** to the repository associated with the Check Run on GitHub.

4.  **Integration**
    -   Directly interacts with the LUCI BuildBucket API using `packages/buildbucket-dart`.
    -   Leverages existing Firestore/LUCI integration logic in `app_dart`.

## Non-Functional Requirements
-   **Performance**: APIs should respond promptly; job scheduling can be asynchronous.
-   **Security**: Ensure proper validation of user permissions before triggering re-runs.
-   **Reliability**: Handle BuildBucket API failures gracefully with informative error responses.

## Acceptance Criteria
-   `rerun_failed_job` successfully schedules a new build for a specific failed job.
-   `rerun_all_failed_jobs` successfully schedules new builds for all failed jobs in a check run.
-   Unauthorized users are blocked with a `403 Forbidden` response.
-   Requests with invalid or missing parameters return a `400 Bad Request`.
-   All new logic is covered by unit tests with >95% coverage.

## Out of Scope
-   Frontend dashboard modifications (this track focus is the backend API).
-   Re-running successful or in-progress jobs.
-   Re-runs of non-LUCI jobs.
