# Specification: Merge Queue Dashboard

## Overview
Create a new standalone dashboard page in the Flutter-based Cocoon dashboard to visualize and manage GitHub Merge Queue events. This tool will allow Flutter EngProd and Release Engineers to monitor merge queue activity, search for specific events, and manually trigger event replays to diagnose and fix integration issues.

## Functional Requirements
- **Standalone Page:** A new route (e.g., `/merge-queue`) in the dashboard application.
- **Data Table:** A scrollable list of merge queue events with the following columns:
    - Document ID (Firestore ID)
    - Date/Time
    - Event/Action (e.g., `dequeued`, `merged`)
    - Base Ref
    - Commit Message
    - Git Hash (Head Commit ID)
- **Search/Filter:** A search bar to filter the displayed list by:
    - Git Hash
    - Base Ref
    - Commit Message
- **Individual Resend Action:** A "Resend" button on each row that calls the `/api/github-webhook-replay` API.
    - **Debouncing:** Disable the "Resend" button for 3 seconds after a click to prevent accidental double-deliveries.
- **Interactive Feedback:**
    - Visual indicator on the row showing the status of the replay attempt (Success/Failure) after the action is triggered.
- **Access Control & Error Handling:**
    - If the fetch from `/api/merge_queue_hooks` fails (e.g., 403 Forbidden for non-Google users), display a clear error message on the screen (e.g., "Access Denied: You must be logged in with a @google.com account").
- **Auto-Refresh:**
    - A dropdown menu to select an auto-refresh interval (e.g., Off, 30s, 1m, 5m).
    - When enabled, the dashboard periodically calls `/api/merge_queue_hooks` to update the event list.
- **Data Source:** Integration with the existing `MergeQueueHooks` API endpoint.

## Non-Functional Requirements
- **Consistency:** Follow Material Design 3 principles as defined in the project's tech stack and product guidelines.
- **Performance:** Efficient rendering of the scrollable list using `ListView.builder` or a Data Table.
- **Responsive Design:** Ensure the table layout is usable on desktop and larger tablet screens.

## Acceptance Criteria
- [ ] Users can navigate to the Merge Queue Dashboard via the navigation menu.
- [ ] The list displays real-time data from the `MergeQueueHooks` endpoint.
- [ ] Users see a clear error message if they lack permission to view the data.
- [ ] Users can search for a specific commit hash and see matching rows.
- [ ] Clicking "Resend" triggers the replay API and disables the button for 3 seconds.
- [ ] The UI visually confirms when a replay request succeeds or fails on the corresponding row.
- [ ] Selecting an auto-refresh interval correctly updates the data periodically.

## Out of Scope
- Bulk resending of events.
- Advanced date-range filtering.
- Editing event data.
