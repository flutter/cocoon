# Specification: Display Commit SHA in Presubmit View Header

## Overview
This track aims to improve the visibility of the specific commit being inspected in the `PreSubmitView` by displaying its short SHA in the header. This helps developers quickly identify which version of the code the CI results pertain to, especially when multiple SHAs are available for a single Pull Request.

## Functional Requirements
- **Display short SHA:** Show the last 7 characters of the commit SHA in the header of the `PreSubmitView`.
- **Header Formatting (Loaded):** When PR details (PR number and author) are available, the header should follow the format: `PR #[pr_number] by [author] ([short_sha])`.
- **Header Formatting (Loading):**
    - If navigated via PR number: The header should show `PR #[pr_number]`.
    - If navigated via SHA: The header should show `([short_sha])`.
    - If neither PR nor SHA is provided: The header should be empty.
- **Plain Text:** The SHA should be displayed as plain text and does not need to be a hyperlink.

## Non-Functional Requirements
- **Consistency:** Ensure the font style (weight, size) matches the existing header elements.
- **Responsiveness:** The header should handle longer author names or PR numbers gracefully (using ellipsis as currently implemented).

## Acceptance Criteria
- [ ] Navigating to a presubmit view for a PR (e.g., `/presubmit?repo=flutter&pr=1234`) displays `PR #1234` while loading and `PR #1234 by [author] ([short_sha])` once loaded.
- [ ] Navigating to a presubmit view via SHA (e.g., `/presubmit?repo=flutter&sha=abcdef1234...`) displays `(abcdef1)` while loading and `PR #[pr_number] by [author] ([short_sha])` once loaded (assuming it's a PR commit).
- [ ] The SHA displayed is exactly 7 characters long.

## Out of Scope
- Linking the SHA to GitHub.
- Displaying the full 40-character SHA.
