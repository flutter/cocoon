# Specification: Implement `getPresubmitGuardsForPullRequest` Request Handler

## Overview
This track involves implementing a new request handler in the `app_dart` service to retrieve all presubmit guards for a specific pull request. It also includes refactoring the `GuardStatus` calculation logic into a shared package for reuse.

## Functional Requirements
- **Refactoring:**
    - Move `GuardStatus` calculation logic from `GetPresubmitGuard` to `packages/cocoon_common/lib/guard_status.dart`.
    - Add a static method or extension to `GuardStatus` that takes `failedBuilds`, `remainingBuilds`, and `totalBuilds` to determine the status.
- **Endpoint:** Create a new GET endpoint: `/api/get-presubmit-guards`.
- **Input Parameters:**
    - `owner`: The GitHub repository owner (default to "flutter").
    - `repo`: The GitHub repository name.
    - `pr`: The pull request number.
- **Service Integration:** Use `UnifiedCheckRun.getPresubmitGuardsForPullRequest` from `app_dart/lib/src/service/firestore/unified_check_run.dart`.
- **Response Data:** A JSON list of presubmit guards. For each guard:
    - `commit_sha`: The SHA of the commit.
    - `check_run_id`: The identifier for the check run.
    - `creation_time`: The creation timestamp.
    - `guard_status`: The calculated status (`New`, `In Progress`, `Failed`, `Succeeded`).
- **Error Handling:**
    - Return **400 Bad Request** if `repo` or `pr` are missing.
    - Return **404 Not Found** if no guards are found.

## Acceptance Criteria
- [ ] `GuardStatus` logic is refactored into `packages/cocoon_common/lib/guard_status.dart`.
- [ ] `GetPresubmitGuard` is updated to use the refactored logic.
- [ ] New handler `GetPresubmitGuards` implemented and registered.
- [ ] Response includes the calculated `guard_status` for each item.
- [ ] Unit tests cover the new endpoint and the refactored logic.
- [ ] Code coverage > 95%.
