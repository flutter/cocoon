# Specification: Add `buildNumber` to `PresubmitCheck`

## Overview
Currently, the `PresubmitCheck` model in Cocoon's Firestore and the corresponding RPC response (`PresubmitCheckResponse`) do not include the canonical LUCI build number. This makes it difficult for backend processes to uniquely identify and link to specific build attempts. This feature adds an optional `buildNumber` field to these models, as well as the intermediate `PresubmitCheckState`, ensuring it is populated when a GitHub `check_run` completion event is processed.

## Goals
- **Improve Traceability:** Provide a direct reference to the LUCI build number in the backend data.
- **Enhanced Context:** Ensure the backend records contain the canonical build number for better auditing and debugging.
- **Future Support:** Lay the groundwork for re-running specific builds using their build number and for future UI integrations.

## Functional Requirements
1.  **Intermediate State Update:** Add a `buildNumber` field (integer, optional) to `PresubmitCheckState` in `app_dart/lib/src/model/common/presubmit_check_state.dart`.
2.  **Firestore Model Update:** Add a `buildNumber` field (integer, optional) to the `PresubmitCheck` document in Firestore.
3.  **RPC Model Update:** Add a `buildNumber` field (integer, optional) to the `PresubmitCheckResponse` RPC model.
4.  **Data Population:** Update `UnifiedCheckRun.markConclusion` (or the relevant handler for `check_run` completion) to:
    -   Fetch the canonical build number from the LUCI BuildBucket API if it's not already available in the incoming `check_run` state.
    -   Store this `buildNumber` in the `PresubmitCheck` document.
5.  **Handling Missing Data:** Older check runs or runs where the build number cannot be retrieved should have the `buildNumber` field set to `null` or omitted.

## Non-Functional Requirements
- **Performance:** Fetching the build number from BuildBucket should not significantly delay the processing of `check_run` events.
- **Reliability:** If fetching the build number fails, the system should still record the completion status without the build number rather than failing the entire transaction.

## Acceptance Criteria
- [ ] `PresubmitCheckState` includes a `buildNumber` field.
- [ ] `PresubmitCheck` documents in Firestore can store a `buildNumber`.
- [ ] `PresubmitCheckResponse` JSON includes a `buildNumber` field when available.
- [ ] When a `check_run` completes, the `buildNumber` is correctly retrieved and stored.
- [ ] Existing check runs without a build number continue to work (field is null).

## Out of Scope
- **Dashboard Integration:** Updating the dashboard UI to display or use the build number is out of scope for this track.
- **Backfilling:** Backfilling build numbers for historical check runs.
- **Rerun Logic:** Implementing the "re-run by build number" functionality.
