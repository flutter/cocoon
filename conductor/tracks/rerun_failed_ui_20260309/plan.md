# Implementation Plan - Re-run Event Handling in Presubmit Guard Details

## Phase 1: Service and State Updates
Update the backend service interface and the state management logic to support re-run operations and track their loading status.

- [ ] Task: Update `CocoonService` interface in `dashboard/lib/service/cocoon.dart` to include optional `include` parameter in `rerunTask`.
- [ ] Task: Update `AppEngineCocoonService` in `dashboard/lib/service/appengine_cocoon.dart` to ensure `rerunTask` correctly overrides the interface.
- [ ] Task: Update `PresubmitState` in `dashboard/lib/state/presubmit.dart` to include re-run methods and state tracking.
    - Add `Set<String> _rerunningTasks` to track which tasks are currently being re-run.
    - Add `bool _isRerunningAll = false` to track if "Re-run failed" is in progress.
    - Implement `Future<String?> rerunTask(String taskName)`:
        - Trigger `rerunTask` API.
        - On success, call `_fetchRefreshUpdate()`.
        - Return error message if any.
    - Implement `Future<String?> rerunFailed()`:
        - Trigger `rerunCommit` API with failed/infra-failure statuses.
        - On success, call `_fetchRefreshUpdate()`.
        - Return error message if any.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Service and State Updates' (Protocol in workflow.md)

## Phase 2: UI Implementation
Update the `PresubmitView` to connect the existing buttons to the new state methods and handle error reporting.

- [ ] Task: Update `_CheckItem` in `dashboard/lib/views/presubmit_view.dart` to:
    - Check if the task is currently being re-run or if "Re-run all" is in progress to disable the button.
    - Check authentication status to disable the button.
    - Call `presubmitState.rerunTask` on press and show error dialog on failure.
- [ ] Task: Update `PresubmitView`'s "Re-run failed" button in `CocoonAppBar` to:
    - Check if "Re-run all" is in progress to disable the button.
    - Check authentication status to disable the button.
    - Call `presubmitState.rerunFailed` on press and show error dialog on failure.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: UI Implementation' (Protocol in workflow.md)
