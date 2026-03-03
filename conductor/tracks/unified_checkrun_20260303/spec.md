# Specification: Unified Checkrun API and PresubmitCheck Model Update

## Overview
This track involves two main objectives:
1.  **Model Enhancement:** Add a `slug` field to the `PresubmitCheck` model in `app_dart`, aligning it with the `PresubmitGuard` model.
2.  **API Unification:** Standardize the query parameters for `GetPresubmitChecks` and `GetPresubmitGuard` request handlers to use `owner` and `repo`, and update the `dashboard` frontend accordingly.

## Functional Requirements
### Backend (app_dart)
1.  **`PresubmitCheck` Model Update:**
    -   Update `PresubmitCheckId` to include `RepositorySlug slug`.
    -   Update `PresubmitCheckId.documentId` to include the slug (format: `owner_repo_checkRunId_buildName_attemptNumber`).
    -   Add `fieldSlug` to `PresubmitCheck` and update the factory/constructor to handle it.
2.  **`GetPresubmitChecks` API Update:**
    -   Add `owner` and `repo` as query parameters.
    -   Update the handler to use these parameters (e.g., to reconstruct the slug for the updated `PresubmitCheck` model).
3.  **`GetPresubmitGuard` API Update:**
    -   Replace the `slug` query parameter with `owner` and `repo`.
    -   Standardize on `owner` and `repo` for identifying the repository.

### Frontend (dashboard)
1.  **Service Update:** Update `AppEngineCocoonService` (`dashboard/lib/service/appengine_cocoon.dart`) to pass `owner` and `repo` instead of `slug` (or in addition to other params) when calling the updated APIs.
2.  **State Update:** Ensure `PresubmitState` (`dashboard/lib/state/presubmit.dart`) correctly provides these parameters.

## Non-Functional Requirements
- **Data Migration:** Be aware that changing `PresubmitCheckId.documentId` will change the Firestore document paths. Ensure this is acceptable or handle backward compatibility if existing data must be preserved.
- **TDD:** Write unit tests for the model changes and the updated request handlers.
- **Coverage:** Maintain >95% code coverage for all modified files.

## Acceptance Criteria
- `PresubmitCheck` documents in Firestore now include a `slug` field.
- `GetPresubmitChecks` successfully retrieves data using `owner`, `repo`, `check_run_id`, and `build_name`.
- `GetPresubmitGuard` successfully retrieves data using `owner`, `repo`, and `sha`.
- Dashboard correctly displays presubmit information using the new API signatures.

## Out of Scope
- Migrating existing `PresubmitCheck` documents in Firestore (this track focuses on the code changes and new entries).
