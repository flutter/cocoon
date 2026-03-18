# Track Specification - Presubmit Dashboard Sorting

## Overview
This track focuses on improving the usability of the Presubmit Dashboard by implementing a consistent sorting logic for checks in the "Presubmit Guard Details View". Users currently find it difficult to locate failed or in-progress tasks when many checks are present. This new sorting logic will prioritize tasks requiring attention (Failed, Infra Failure, In Progress) and organize them alphabetically within each status.

## Functional Requirements
- Implement sorting for checks in the `Presubmit Guard Details View` of the Flutter dashboard.
- The primary sort criteria is the **Task Status** following this priority order (highest to lowest):
    1.  Failed
    2.  Infra Failure
    3.  In Progress
    4.  New (waitingForBackfill)
    5.  Cancelled
    6.  Skipped
    7.  Succeeded
- The secondary sort criteria is the **Check Name** (alphabetical, ascending) within each status.
- This sorting logic must be the **Fixed Default** behavior for the Details View.
- The sorting should be handled entirely within the **Frontend (Dashboard)** using data already provided by the backend APIs.

## Non-Functional Requirements
- **Performance:** Sorting should be efficient and not cause noticeable latency in the UI, even for checks with many tasks.
- **Maintainability:** Sorting logic should be encapsulated in a reusable utility or within the relevant Flutter component to ensure it's easy to test and update.
- **Consistency:** Ensure the UI correctly updates and reflects the sorted order whenever task data is refreshed.

## Acceptance Criteria
- [ ] In the `Presubmit Guard Details View`, checks are sorted first by status according to the specified priority.
- [ ] Within the same status, checks are sorted alphabetically by their name.
- [ ] The sorting is applied automatically when the view is loaded or data is updated.
- [ ] The implementation includes unit tests covering various combinations of statuses and names to verify correct sorting.
- [ ] >95% code coverage for the new sorting logic and its integration.

## Out of Scope
- Backend API modifications for pre-sorted data.
- User-selectable sorting options or toggles.
- Sorting in the "Presubmit Guard Summary View" (unless explicitly requested later).
- Sorting of other dashboards or views in Cocoon.
