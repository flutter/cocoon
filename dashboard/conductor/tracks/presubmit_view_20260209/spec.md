# Specification - Pull Request Detailed View (PreSubmitView)

## Overview
Implement a detailed monitoring view for a specific Pull Request (PR) in the Flutter Dashboard, based on the provided layout (`code.html` and `screen.png`). This view allows maintainers to inspect CI check statuses and view execution logs for a specific commit SHA or a mocked Pull Request.

## Functional Requirements
- **Deep Link Navigation:** The view must be accessible via query parameters:
    - `?repo=<repo>&sha=<commitSha>`: **Functional Route**.
    - `?repo=<repo>&pr=<prNumber>`: **Mocked Route**. Displays placeholder data based on the provided layout.
- **Data Integration (Checks Sidebar):**
    - For the functional `sha` route, the sidebar MUST be populated by calling the Cocoon API:
      `GET /api/get-presubmit-guard?slug=flutter/<repo>&sha=<commitSha>`
    - **API Response Handling:** The UI must parse the `PresubmitGuardResponse` and map it to the sidebar:
        - `stages`: Map each stage to a sidebar section (e.g., Engine, Framework).
        - `builds` (within stages): Map each build entry to an individual check item with its name and status.
        - `author` and `prNum`: Use these to update the header metadata.
        - `guardStatus`: Reflect the overall status in the header.
        - **`checkRunId`**: Store this ID, as it is required to fetch specific check details/logs.
- **Checks Sidebar UI:**
    - List CI checks grouped by section (from API stages).
    - Show status icons (Success, Error, Pending) mapped from API build statuses.
    - **Re-run Actions (Mocked):** Buttons provide visual feedback when clicked but do not perform backend actions.
- **Log Viewer Pane:**
    - Display the "Execution Log" for the selected check in the sidebar.
    - For the functional `sha` route, fetch the check details using the Cocoon API:
      `GET /api/get-presubmit-checks?check_run_id=<check_run_id>&build_name=<build_name>`
    - **Handling Multiple Attempts (Tabs):**
        - If the API returns multiple `PresubmitCheckResponse` objects for a build, display them as tabs in the log viewer (as shown in the layout).
        - **Tab Naming:** Use the `attemptNumber` prefixed with a hash as the tab label (e.g., `#1`, `#2`).
        - Selecting a tab displays the `summary` or log content from that specific attempt.
    - Include a link to view details on the external LUCI UI.
    - For the mocked `pr` route: Use placeholder log content and tabs.
- **Dark Mode Support:** Implement the layout's dark mode theme, consistent with the project's visual identity.

## Non-Functional Requirements
- **Material Design 3:** Adhere to the project's tech stack and visual guidelines while implementing the specific layout provided.
- **Responsiveness:** Correctly handle sidebar and log pane on different screen sizes.
- **Accessibility:** Adhere to WCAG 2.1 Level AA standards for new UI components.

## Acceptance Criteria
- [ ] Navigating to `?repo=flutter&sha=<sha>` correctly calls the `/api/get-presubmit-guard` endpoint and renders the sidebar.
- [ ] Navigating to `?repo=flutter&pr=<pr>` displays the mocked dashboard layout.
- [ ] Selecting a check in the sidebar correctly calls the `/api/get-presubmit-checks` endpoint (for functional SHA routes).
- [ ] Multiple attempts for a check are displayed as clickable tabs labeled by their attempt number.
- [ ] The UI supports both Light and Dark modes.

## Out of Scope
- Main PR list/dashboard page.
- Functional backend integration for re-running tasks.
- Real-time log streaming.
- Navigation/Browsing between different Pull Requests (beyond basic URL entry).
- Log download functionality.
