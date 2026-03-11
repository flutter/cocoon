# Specification - Re-run Event Handling in Presubmit Guard Details

## Overview
Implement event handling and authentication for the existing "Re-run" and "Re-run failed" buttons in the Presubmit Guard Details view of the Cocoon dashboard. This enables authenticated users to trigger CI re-runs for failed checks directly from the UI.

## Functional Requirements
*   **Re-run Event Handling:**
    *   Connect the existing **"Re-run"** buttons (per job) to trigger the **`/api/rerun-failed-job`** API call.
    *   **UI Logic:** Disable only the specific "Re-run" button while the request is pending.
*   **Re-run Failed Event Handling:**
    *   Connect the existing **"Re-run failed"** button to trigger the **`/api/rerun-all-failed-jobs`** API call.
    *   **UI Logic:** Disable the "Re-run failed" button AND all individual "Re-run" buttons while the request is pending.
*   **State Management:**
    *   After a successful re-run request, call `_fetchRefreshUpdate` (or equivalent) to refresh the check-run states in the UI.
    *   The UI must automatically refresh the check-run states when the user's authentication status changes (e.g., after login or logout).
*   **Authentication & Permissions:**
    *   If the user is **not authenticated**, the "Re-run" and "Re-run failed" buttons must be **disabled**.
*   **Error Handling:**
    *   If the API call returns an error, show a **popup dialog** displaying the error code and response message (if any).
*   **Data Seeding (Backend/Integration Test):**
    *   Update `_seedPresubmitData` to seed the `prCheckRuns` collection in Firestore.
    *   Each seeded `prCheckRuns` document must include a dummy `pull_request` object with all fields required by the `_scheduleTryBuilds` method (head.sha, base.repo, base.ref, user.login, number, labels).

## Non-Functional Requirements
*   **Performance:** UI updates should be responsive, providing immediate feedback (button disabling) upon user interaction.

## Acceptance Criteria
*   [ ] Clicking "Re-run" for a failed job triggers the correct API call.
*   [ ] Clicking "Re-run failed" triggers the correct API call for all failed jobs.
*   [ ] If the user is unauthenticated, all re-run buttons are disabled.
*   [ ] Clicking "Re-run" disables only that button until the API call completes.
*   [ ] Clicking "Re-run failed" disables all re-run buttons until the API call completes.
*   [ ] The UI refreshes its state after a successful re-run trigger.
*   [ ] Errors from the API are displayed in a popup dialog.

## Out of Scope
*   Implementing the backend API endpoints (assumed to already exist).
*   UI layout or adding new buttons (they are already present).
