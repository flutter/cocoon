# Track Specification: Public Presubmit APIs

## Overview
This track aims to make certain presubmit-related APIs public by refactoring the request handler hierarchy in `app_dart`. Currently, these APIs require authentication because they inherit from `ApiRequestHandler`. We will introduce a new base class, `PublicApiRequestHandler`, to house common logic (like parameter validation) without enforcing authentication, and then transition the target APIs to use this new base.

## Functional Requirements
1.  **Introduce `PublicApiRequestHandler`**:
    *   Create a new abstract base class `PublicApiRequestHandler` that extends `RequestHandler`.
    *   Move utility methods `checkRequiredParameters` and `checkRequiredQueryParameters` from `ApiRequestHandler` to `PublicApiRequestHandler`.
2.  **Refactor `ApiRequestHandler`**:
    *   Update `ApiRequestHandler` to extend `PublicApiRequestHandler`.
    *   Retain authentication logic and `authContext` access within `ApiRequestHandler`.
3.  **Expose APIs Publicly**:
    *   Update the following handlers to extend `PublicApiRequestHandler` instead of `ApiRequestHandler`:
        *   `GetPresubmitJobs`
        *   `GetPresubmitGuardSummaries`
        *   `GetPresubmitGuard`
    *   Remove the `authenticationProvider` requirement from their constructors.

## Non-Functional Requirements
1.  **Maintainability**: Ensure the new hierarchy is clean and follows existing project patterns.
2.  **Testability**: Ensure that the refactored handlers are still easily testable and that their core logic remains unchanged.

## Acceptance Criteria
1.  `PublicApiRequestHandler` is correctly implemented and used as a base for `ApiRequestHandler`.
2.  `GetPresubmitJobs`, `GetPresubmitGuardSummaries`, and `GetPresubmitGuard` no longer require authentication to be called.
3.  Existing unit tests for these handlers pass (with adjustments to the constructor/setup where necessary).
4.  New tests verify that these APIs are accessible without an authentication token.
5.  **Code Quality**: Running `dart format --set-exit-if-changed .` and `dart analyze --fatal-infos .` in `app_dart` results in no warnings or formatting issues.

## Out of Scope
*   Updating the Dashboard to remove authentication headers (as confirmed by the user).
*   Making other APIs public beyond the three specified.
