# Implementation Plan - Presubmit Dashboard Job Filtering

This plan outlines the steps to add job filtering to the Presubmit Dashboard in the Cocoon dashboard.

## Phase 1: State Management (PresubmitState) [checkpoint: 48bff29]
In this phase, we will extend `PresubmitState` to hold and manage the filter state.

- [x] **Task: Add filter state variables to `PresubmitState`.**
    - Variables: `Set<TaskStatus> selectedStatuses`, `Set<String> selectedPlatforms`, `String? jobNameFilter`.
    - Initialize with all statuses and platforms selected, and `null` or empty string for regex.
- [x] **Task: Add methods to update filter state.**
    - `updateFilters({Set<TaskStatus>? statuses, Set<String>? platforms, String? jobNameFilter})`
    - `clearFilters()`: Resets filters to "select all" and clear regex.
- [x] **Task: Implement filtering logic in `PresubmitState`.**
    - Add a getter `filteredGuardResponse` (or similar) that returns a `PresubmitGuardResponse` with filtered stages and builds based on the active filters.
    - Platforms are extracted by splitting job names by space and taking the first part.
- [x] **Task: Add unit tests for `PresubmitState` filtering logic.**
    - Verify filtering by status, platform, and regex.
    - Verify persistence when `update` is called with same PR but different SHA.
- [x] **Task: Conductor - User Manual Verification 'Phase 1: State Management' (Protocol in workflow.md)**

## Phase 2: Filter Dialog UI [checkpoint: 2903a30]
In this phase, we will create the filter dialog and its components.

- [x] **Task: Create `FilterDialog` widget in `dashboard/lib/widgets/filter_dialog.dart`.**
    - Multi-select sections for Task Status and Platform.
    - `TextField` for Job Name Regex (with `onChanged` or `onEditingComplete` depending on final behavior).
    - Validation: Ensure at least one status and one platform are always selected (disable uncheck if it's the last one).
    - "Clear all filters" button at the bottom.
    - "Show N jobs" button displaying the filtered count.
- [x] **Task: Add unit tests for `FilterDialog`.**
    - Verify initial state shows all filters.
    - Verify toggling selections updates the UI and buttons.
- [x] **Task: Conductor - User Manual Verification 'Phase 2: Filter Dialog UI' (Protocol in workflow.md)**

## Phase 3: Integration and Dashboard UI [checkpoint: b499002]
In this phase, we will integrate the filter functionality into the Presubmit Dashboard.

- [x] **Task: Add Filter Button to `CocoonAppBar` in `PreSubmitView`.**
    - Icon: `Icons.filter_alt_outlined` (no filters applied) or `Icons.filter_alt` (some filters applied).
    - Tooltip: "Filter jobs".
    - Hover highlight: "Filter jobs".
- [x] **Task: Update `PreSubmitView` to use `filteredGuardResponse` for `_ChecksSidebar`.**
- [x] **Task: Ensure filter state persists when switching guard statuses.**
    - Handled by `PresubmitState` during `update` calls.
- [x] **Task: Add integration tests for filtering functionality in `PreSubmitView`.**
    - Verify clicking the filter button opens the dialog.
    - Verify applying filters updates the `_ChecksSidebar`.
- [x] **Task: Conductor - User Manual Verification 'Phase 3: Integration and Dashboard UI' (Protocol in workflow.md)**

## Phase 4: Final Polishing and Cleanup [checkpoint: e03cad0]
- [x] **Task: Verify overall dashboard performance with active filters.**
- [x] **Task: Ensure accessibility (ARIA labels, tooltips).**
- [x] **Task: Conductor - User Manual Verification 'Phase 4: Final Polishing and Cleanup' (Protocol in workflow.md)**
