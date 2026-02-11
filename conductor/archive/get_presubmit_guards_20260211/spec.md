# Specification: Implement `getPresubmitGuardSummaries` Request Handler

## Overview
This track involves implementing a new request handler in the `app_dart` service to retrieve a summary of presubmit guards for a specific pull request, grouped by commit SHA. It also includes refactoring the `GuardStatus` calculation logic and creating a shared RPC model.

## Functional Requirements
- **Refactoring:**
    - Moved `GuardStatus` calculation logic to `packages/cocoon_common/lib/guard_status.dart` as a static `calculate` method.
    - Updated existing `GetPresubmitGuard` handler to use the centralized logic.
- **RPC Model:**
    - Created `PresubmitGuardSummary` model in `packages/cocoon_common` to represent the aggregated status of guards for a single commit SHA.
- **Endpoint:** Created a new GET endpoint: `/api/get-presubmit-guard-summaries`.
- **Input Parameters:**
    - `repo`: The GitHub repository name (required).
    - `pr`: The pull request number (required).
    - `owner`: The GitHub repository owner (optional, defaults to "flutter").
- **Service Integration:** Uses `UnifiedCheckRun.getPresubmitGuardsForPullRequest` to fetch all guards for the PR.
- **Grouping Logic:** Guards are grouped by `commit_sha`. For each group, the status is aggregated using `GuardStatus.calculate` based on the sum of failed, remaining, and total builds across all stages for that SHA.
- **Response Data:** A JSON array of `PresubmitGuardSummary` objects:
    - `commit_sha`: The SHA of the commit.
    - `creation_time`: The latest creation timestamp among all guards for that SHA.
    - `guard_status`: The aggregated status (`New`, `In Progress`, `Failed`, `Succeeded`).
- **Error Handling:**
    - Returns **400 Bad Request** if `repo` or `pr` are missing.
    - Returns **404 Not Found** if no guards are found for the PR.

## Acceptance Criteria
- [x] `GuardStatus.calculate` implemented and tested.
- [x] `GetPresubmitGuard` refactored to use `GuardStatus.calculate`.
- [x] `PresubmitGuardSummary` RPC model created and exported.
- [x] `GetPresubmitGuardSummaries` handler implemented with grouping and aggregation logic.
- [x] Endpoint registered at `/api/get-presubmit-guard-summaries`.
- [x] Unit tests cover all requirements and grouping logic.
- [x] Code coverage > 95%.
