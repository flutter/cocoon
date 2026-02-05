# Implementation Plan: Merge Queue Dashboard

## Phase 1: Service Layer Integration
- [ ] Task: Write Tests for `fetchMergeQueueHooks` and `replayGitHubWebhook` in `CocoonService`.
    - [ ] Add tests to `dashboard/test/service/appengine_cocoon_test.dart` (or create a new test file).
    - [ ] Define expected behavior for successful fetches (List of `MergeGroupHook`) and successful replays (POST request).
    - [ ] Define expected behavior for access denied (403) and other API errors.
- [ ] Task: Update `CocoonService` interface and implement in `AppEngineCocoonService`.
    - [ ] Add `fetchMergeQueueHooks` to `CocoonService` in `dashboard/lib/service/cocoon.dart`.
    - [ ] Add `replayGitHubWebhook` to `CocoonService` in `dashboard/lib/service/cocoon.dart`.
    - [ ] Implement `fetchMergeQueueHooks` (GET `/api/merge_queue_hooks`) in `AppEngineCocoonService`.
    - [ ] Implement `replayGitHubWebhook` (POST `/api/github-webhook-replay?id=...`) in `AppEngineCocoonService`.
    - [ ] Ensure the `idToken` is included in the headers for both requests.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Service Layer Integration' (Protocol in workflow.md)

## Phase 2: State Management
- [ ] Task: Write Tests for `MergeQueueState`.
    - [ ] Create `dashboard/test/state/merge_queue_test.dart`.
    - [ ] Test initial state, successful data fetching, and handling of 403 Forbidden errors.
    - [ ] Test searching/filtering logic by commit hash, ref, and message.
    - [ ] Test auto-refresh timer logic and debounce logic for the "Resend" action.
- [ ] Task: Implement `MergeQueueState`.
    - [ ] Create `dashboard/lib/state/merge_queue.dart` extending `ChangeNotifier`.
    - [ ] Integrate `CocoonService` and `FirebaseAuthService`.
    - [ ] Implement the `fetch` logic with state variables for loading, error, and filtered data.
    - [ ] Implement the 3-second debounce logic for the `replay` action.
    - [ ] Implement auto-refresh logic based on a user-selectable interval.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: State Management' (Protocol in workflow.md)

## Phase 3: Dashboard View & UI
- [ ] Task: Write Widget and Golden Tests for `MergeQueueDashboard`.
    - [ ] Create `dashboard/test/views/merge_queue_dashboard_test.dart`.
    - [ ] Verify that the dashboard displays an error message when access is denied.
    - [ ] Verify that the search bar correctly triggers filtering.
    - [ ] Verify that the "Resend" button is disabled during the debounce period.
    - [ ] **Golden Test:** Create a golden image test to ensure the UI renders correctly (data table, search bar, buttons) across different screen sizes.
- [ ] Task: Implement `MergeQueueDashboard` view.
    - [ ] Create `dashboard/lib/views/merge_queue_dashboard_page.dart`.
    - [ ] Implement the UI layout using a `Scaffold` with a header for Search and Auto-Refresh controls.
    - [ ] Implement the data table to display Merge Queue event details.
    - [ ] Connect the UI to `MergeQueueState` and provide visual feedback for resend actions.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Dashboard View & UI' (Protocol in workflow.md)

## Phase 4: Navigation & Integration
- [ ] Task: Write Tests for navigation and routing.
    - [ ] Update `dashboard/test/main_test.dart` or similar to verify the new route.
- [ ] Task: Register the new route and add navigation.
    - [ ] Update `dashboard/lib/main.dart` to include the `/merge-queue` route in `onGenerateRoute`.
    - [ ] Update `dashboard/lib/logic/links.dart` to add the "Merge Queue" link to the navigation drawer.
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Navigation & Integration' (Protocol in workflow.md)
