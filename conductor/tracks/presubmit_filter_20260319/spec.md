# Specification - Presubmit Dashboard Job Filtering (v4)

## Overview
This track aims to enhance the Presubmit Dashboard in the Cocoon dashboard by adding a filtering mechanism for CI jobs displayed in the `_ChecksSidebar`. This will allow users to quickly narrow down relevant jobs based on status, platform, and name (via regex), improving the usability and actionable visibility of build health.

## Functional Requirements
*   **Filter Button in CocoonAppBar:**
    -   Add a filter icon button to the `CocoonAppBar` actions in the Presubmit Dashboard.
    -   Icon: `Icons.filter_alt_outlined` (no filters applied) or `Icons.filter_alt` (some filters applied).
    -   Tooltip: "Filter jobs".
*   **Filter Dialog:**
    -   Clicking the filter button opens a dialog.
    -   **Status Filter:** Multi-select list of all possible task statuses (e.g., Succeeded, Failed, In Progress, Queued, Skipped, etc.).
    -   **Platform Filter:** Multi-select list of platform names, derived by splitting all unique job names by space and taking the first part.
    -   **Job Name Regex Filter:** Text input for a regular expression to match against job names.
    -   **Validation:** At least one task status and at least one platform must remain checked at all times.
    -   **Clear All Filters:** A button at the bottom to reset all filters to their default state (all selected, regex empty).
    -   **Show N Jobs:** A button displaying the total count of filtered jobs in the `_ChecksSidebar`.
*   **Filtering Logic:**
    -   Filters apply immediately when a status or platform is toggled.
    -   Regex filter applies when the input field loses focus (onBlur).
    -   The `_ChecksSidebar` list of jobs updates in real-time based on the active filters.
*   **Persistence & State:**
    -   Filter state is managed in `PresubmitState`.
    -   Filters should remain if the user selects a different guard status.
*   **Visual Elements:**
    -   Filter button should be `Icons.filter_alt_outlined` if no filters are applied, and `Icons.filter_alt` if some filters are applied.
    -   Filter button should have text highlight "Filter jobs" on mouse over.

## Non-Functional Requirements
*   **Material Design:** Follow Material Design principles for the dialog and filter button.
*   **Performance:** Filtering should be efficient, even with a large number of jobs.
*   **Accessibility:** Use appropriate tooltips and labels for filter controls.

## Acceptance Criteria
- [ ] Filter button in `CocoonAppBar` changes icon based on active filter state.
- [ ] Filter dialog shows all active filters correctly upon opening.
- [ ] `_ChecksSidebar` correctly displays only the jobs matching the active status, platform, and regex filters.
- [ ] "Show N jobs" button reflects the correct count of filtered jobs.
- [ ] At least one status and one platform are always selected in the dialog.
- [ ] "Clear all filters" button resets the filter state.
- [ ] Filter state persists when navigating between different guard statuses.

## Out of Scope
- [ ] Permanent persistence of filters across browser sessions (e.g., in LocalStorage).
- [ ] Complex multi-regex or boolean logic filters.
- [ ] Filtering logic on the backend; all filtering is performed client-side in the Flutter dashboard.
