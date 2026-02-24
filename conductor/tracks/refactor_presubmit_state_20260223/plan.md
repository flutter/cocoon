# Implementation Plan - Refactor PreSubmitView State Management

## Phase 1: Foundation - Create PresubmitState [checkpoint: 584afaa]
This phase focuses on creating the new `PresubmitState` class and migrating the core data fetching logic.

- [x] Task: Create `dashboard/lib/state/presubmit.dart` with `PresubmitState` class, including `repo`, `pr`, and `sha` properties.
- [x] Task: Implement initialization and update methods for `repo`, `pr`, and `sha` in `PresubmitState`.
- [x] Task: Implement `fetchAvailableShas` and `fetchGuardStatus` in `PresubmitState`.
- [x] Task: Write unit tests for `PresubmitState` in `dashboard/test/state/presubmit_test.dart`.
- [x] Task: Conductor - User Manual Verification 'Phase 1: Foundation' (Protocol in workflow.md)

## Phase 2: Refactor PreSubmitView
This phase integrates `PresubmitState` into the main `PreSubmitView` widget and removes its local state.

- [x] Task: Update `dashboard/lib/main.dart` or the relevant state provider to instantiate and provide `PresubmitState`.
- [~] Task: Refactor `_PreSubmitViewState` to use `PresubmitState` for context management (repo, pr, sha) and data fetching.
- [ ] Task: Update `dashboard/test/views/presubmit_view_test.dart` to ensure compatibility with the new state management.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Refactor PreSubmitView' (Protocol in workflow.md)

## Phase 3: Refactor LogViewerPane and Finalize
This phase completes the migration by moving the check details logic and performing final verification.

- [ ] Task: Implement `fetchCheckDetails` and associated state (`selectedCheck`, `checks`) in `PresubmitState`.
- [ ] Task: Refactor `_LogViewerPaneState` in `dashboard/lib/views/presubmit_view.dart` to use `PresubmitState`.
- [ ] Task: Final verification of `PreSubmitView` functionality and test coverage.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Refactor LogViewerPane and Finalize' (Protocol in workflow.md)
