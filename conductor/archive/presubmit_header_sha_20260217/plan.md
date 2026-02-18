# Implementation Plan: Display Commit SHA in Presubmit View Header

This plan outlines the steps to add the commit SHA to the header of the `PreSubmitView` in the Cocoon dashboard, following the approved specification and the project's TDD workflow.

## Phase 1: Implementation of SHA Header [checkpoint: 6ce5030]

This phase focuses on the core logic and UI changes for displaying the short SHA in the header.

- [x] Task: Implement SHA Display in PreSubmitView Header
    - [x] Task: Red Phase: Create/update unit tests in `dashboard/test/views/presubmit_view_test.dart` to verify header text for:
        - [x] Loading state (navigated via PR).
        - [x] Loading state (navigated via SHA).
        - [x] Loaded state (displaying `PR #... by ... (sha)`).
    - [x] Task: Green Phase: Update the `title` logic in `_PreSubmitViewState.build` to match the specification.
    - [x] Task: Verify that all tests in `dashboard/test/views/presubmit_view_test.dart` pass.
    - [x] Task: Verify that code coverage for `dashboard/lib/views/presubmit_view.dart` meets the >95% requirement.
- [x] Task: Conductor - User Manual Verification 'Phase 1: Implementation of SHA Header' (Protocol in workflow.md)

## Phase 2: Final Verification and Cleanup [checkpoint: 512b93c]

- [x] Task: Comprehensive Dashboard Test Suite Execution
    - [x] Run all dashboard tests to ensure no regressions: `flutter test` in `dashboard/`.
- [x] Task: Conductor - User Manual Verification 'Phase 2: Final Verification and Cleanup' (Protocol in workflow.md)
