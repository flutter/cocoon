# Implementation Plan: Display Commit SHA in Presubmit View Header

This plan outlines the steps to add the commit SHA to the header of the `PreSubmitView` in the Cocoon dashboard, following the approved specification and the project's TDD workflow.

## Phase 1: Implementation of SHA Header

This phase focuses on the core logic and UI changes for displaying the short SHA in the header.

- [ ] Task: Implement SHA Display in PreSubmitView Header
    - [ ] Task: Red Phase: Create/update unit tests in `dashboard/test/views/presubmit_view_test.dart` to verify header text for:
        - [ ] Loading state (navigated via PR).
        - [ ] Loading state (navigated via SHA).
        - [ ] Loaded state (displaying `PR #... by ... (sha)`).
    - [ ] Task: Green Phase: Update the `title` logic in `_PreSubmitViewState.build` to match the specification.
    - [ ] Task: Verify that all tests in `dashboard/test/views/presubmit_view_test.dart` pass.
    - [ ] Task: Verify that code coverage for `dashboard/lib/views/presubmit_view.dart` meets the >95% requirement.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Implementation of SHA Header' (Protocol in workflow.md)

## Phase 2: Final Verification and Cleanup

- [ ] Task: Comprehensive Dashboard Test Suite Execution
    - [ ] Run all dashboard tests to ensure no regressions: `flutter test` in `dashboard/`.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Final Verification and Cleanup' (Protocol in workflow.md)
