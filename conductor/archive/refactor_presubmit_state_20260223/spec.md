# Specification - Refactor PreSubmitView State Management

## Overview
This track involves refactoring the `PreSubmitView` to move its state and logic into a dedicated `PresubmitState` class, following the pattern used by `BuildDashboardPage` and `BuildState`. This will improve code organization, testability, and consistency across the Cocoon dashboard.

## Goals
- Extract all data fetching and processing logic from `PreSubmitView` into `PresubmitState`.
- Centralize state management for PR summaries, guard statuses, and check details.
- Align the architecture of `PreSubmitView` with the project's established patterns.

## Functional Requirements
- **PresubmitState Class:**
    - Inherit from `ChangeNotifier`.
    - Hold context properties: `repo`, `pr`, and `sha`.
    - Handle fetching available SHAs for a PR (`fetchAvailableShas`).
    - Handle fetching guard status for a specific SHA (`fetchGuardStatus`).
    - Handle fetching check details/logs (`fetchCheckDetails`).
    - Expose state properties: `repo`, `pr`, `sha`, `guardResponse`, `isLoading`, `availableSummaries`, `selectedCheck`, `checks`.
- **PreSubmitView Integration:**
    - Use `Provider.of<PresubmitState>` to access state and trigger actions.
    - Remove local state variables and direct `CocoonService` calls from `_PreSubmitViewState`.
- **LogViewerPane Integration:**
    - Use `PresubmitState` for fetching and displaying check details.
    - Remove local state variables from `_LogViewerPaneState`.

## Non-Functional Requirements
- **Consistency:** Follow the adaptive alignment with `BuildState`.
- **Testability:** The new `PresubmitState` should be easily testable in isolation.

## Acceptance Criteria
- `PreSubmitView` functions identically to its current implementation from a user perspective.
- `PreSubmitView` and its sub-widgets do not hold local state for data fetched from the backend.
- Existing tests for `PreSubmitView` pass after the refactor.
- New unit tests for `PresubmitState` cover the migrated logic.

## Out of Scope
- Changing the UI layout or design of `PreSubmitView`.
- Implementing new features or fixing unrelated bugs in `PreSubmitView`.
