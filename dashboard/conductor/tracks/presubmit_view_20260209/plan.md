# Implementation Plan - Pull Request Detailed View

## Phase 1: Infrastructure & Data Model [checkpoint: 085b744]
- [x] Task: Define the `PresubmitGuardResponse` and `PresubmitCheckResponse` models. (3c968d9)
    - [x] Write Tests: Create unit tests for the new models, ensuring correct JSON deserialization based on the Cocoon API structure. (3c968d9)
    - [x] Implement: Reuse model classes from `cocoon_common`. (3c968d9)
- [x] Task: Integrate the new endpoints into `CocoonService`. (3c968d9)
    - [x] Write Tests: Mock the `/api/get-presubmit-guard` and `/api/get-presubmit-checks` endpoints and verify the service correctly fetches and parses the data. (3c968d9)
    - [x] Implement: Add `fetchPresubmitGuard` and `fetchPresubmitCheckDetails` methods to `CocoonService` and its implementations. (3c968d9)
- [x] Task: Conductor - User Manual Verification 'Phase 1: Infrastructure & Data Model' (Protocol in workflow.md) (085b744)

## Phase 2: UI Implementation - Sidebar & Header
- [x] Task: Create the `PreSubmitView` page scaffold and routing. (3eac01d)
    - [x] Write Tests: Verify that the application correctly routes to the new view using query parameters (`?repo=...&sha=...` and `?repo=...&pr=...`). (3eac01d)
    - [x] Implement: Add the new route and create the basic `PreSubmitView` widget. (3eac01d)
- [x] Task: Implement the Header and Metadata components. (3eac01d)
    - [x] Write Tests: Create widget tests to ensure PR number, title, and author are displayed correctly (mocked or from API). (3eac01d)
    - [x] Implement: Build the header following the layout in `code.html`. (3eac01d)
- [x] Task: Implement the Checks Sidebar UI. (3eac01d)
    - [x] Write Tests: Verify that checks are correctly grouped by stage and show the correct status icons. (3eac01d)
    - [x] Implement: Build the scrollable sidebar with grouping and "Re-run" buttons (mocked actions). (3eac01d)
- [x] Task: Conductor - User Manual Verification 'Phase 2: UI Implementation - Sidebar & Header' (Protocol in workflow.md)

## Phase 3: UI Implementation - Log Viewer & Integration
- [x] Task: Implement the Log Viewer Pane with Attempt Tabs. (3eac01d)
    - [x] Write Tests: Verify that clicking a check in the sidebar updates the log pane and that attempt tabs correctly switch between log summaries. (3eac01d)
    - [x] Implement: Build the tabbed log viewer and the log content area. (3eac01d)
- [x] Task: Integrate real data for the `sha` route. (3eac01d)
    - [x] Write Tests: Verify that the `sha` route correctly triggers API calls and populates the UI with live data. (3eac01d)
    - [x] Implement: Connect the `sha` route logic to the `CocoonService`. (3eac01d)
- [x] Task: Implement the mocked `pr` route. (3eac01d)
    - [x] Write Tests: Verify that the `pr` route displays the placeholder data from the layout. (3eac01d)
    - [x] Implement: Add the fallback/mocked data logic for the `pr` query parameter. (3eac01d)
- [~] Task: Final Accessibility & Dark Mode Pass.
    - [ ] Write Tests: Run accessibility audits and verify high contrast/screen reader support for the new view.
    - [ ] Implement: Refine styling for perfect WCAG 2.1 Level AA compliance and ensure seamless Dark Mode switching.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: UI Implementation - Log Viewer & Integration' (Protocol in workflow.md)
