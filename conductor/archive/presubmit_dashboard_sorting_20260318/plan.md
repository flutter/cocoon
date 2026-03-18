# Implementation Plan - Presubmit Dashboard Sorting [checkpoint: 6de1e57]

Implement sorting of checks in the Presubmit Guard Details view by status first (priority: Failed, Infra Failure, In Progress, New, Cancelled, Skipped, Succeeded) and then alphabetically by name.

## User Review Required

> [!IMPORTANT]
> This change only affects the `_ChecksSidebar` in `PreSubmitView`. The sorting is fixed and applied to every stage within the view.

- **Status Priority Order:**
  1. Failed
  2. Infra Failure
  3. In Progress
  4. New (waitingForBackfill)
  5. Cancelled
  6. Skipped
  7. Succeeded

## Proposed Changes

### Dashboard Logic

#### [x] Task: Create task sorting utility
- Create `dashboard/lib/logic/task_sorting.dart`.
- Implement `compareTasks(String nameA, TaskStatus statusA, String nameB, TaskStatus statusB)` function.
- Implement `_statusPriority(TaskStatus status)` helper.

### Dashboard Views

#### [x] Task: Apply sorting to `_ChecksSidebar`
- Modify `dashboard/lib/views/presubmit_view.dart`.
- Import `../logic/task_sorting.dart`.
- In `_ChecksSidebar.build`, sort `stage.builds.entries` before mapping them to `_CheckItem`.

## Verification Plan

### Automated Tests
- Create `dashboard/test/logic/task_sorting_test.dart` to verify the sorting logic with various status and name combinations.
- Add a test case to `dashboard/test/views/presubmit_view_test.dart` to ensure that checks are rendered in the expected sorted order.

### Manual Verification
1. Open the Cocoon dashboard.
2. Navigate to a PR's presubmit details page.
3. Verify that the checks in the sidebar are sorted correctly by status first, then by name.
4. Ensure Failed and Infra Failure tasks appear at the top of their respective stages.

- [x] Task: Conductor - User Manual Verification 'Presubmit Dashboard Sorting' (Protocol in workflow.md)
