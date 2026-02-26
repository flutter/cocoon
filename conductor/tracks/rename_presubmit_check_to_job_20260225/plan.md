# Implementation Plan: Rename PresubmitCheck to PresubmitJob

## Phase 1: Shared Packages & Protos

### Tasks
- [ ] Task: Rename symbols in `packages/cocoon_common`
    - [ ] Update `PresubmitCheck` to `PresubmitJob` in code and tests.
    - [ ] Update documentation and comments.
- [ ] Task: Update Proto Definitions and Generate Code
    - [ ] Find and update all `.proto` files containing `PresubmitCheck`.
    - [ ] Run code generation script (`protofu.yaml` or equivalent).
    - [ ] Update any manual wrappers or extensions in `app_dart/lib/protos.dart`.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Shared Packages & Protos' (Protocol in workflow.md)

## Phase 2: Backend (app_dart & auto_submit)

### Tasks
- [ ] Task: Refactor `app_dart` Backend
    - [ ] Rename classes, variables, and endpoints in `app_dart/lib/`.
    - [ ] Update Firestore collection/field references.
    - [ ] Update tests in `app_dart/test/`.
- [ ] Task: Refactor `auto_submit` Bot
    - [ ] Rename symbols in `auto_submit/lib/`.
    - [ ] Update logic for handling presubmit jobs.
    - [ ] Update tests in `auto_submit/test/`.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Backend (app_dart & auto_submit)' (Protocol in workflow.md)

## Phase 3: Frontend (dashboard)

### Tasks
- [ ] Task: Refactor `dashboard` Frontend
    - [ ] Rename UI components, state variables, and API clients.
    - [ ] Update localized strings and display labels.
    - [ ] Update tests in `dashboard/test/`.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Frontend (dashboard)' (Protocol in workflow.md)

## Phase 4: Infrastructure & Documentation

### Tasks
- [ ] Task: Update Configuration Files
    - [ ] Update `app.yaml`, `config.yaml`, and `.ci.yaml` in all directories.
    - [ ] Verify Cloud Build configuration references.
- [ ] Task: Global Documentation Update
    - [ ] Update `README.md` files and any other documentation in `docs/`.
- [ ] Task: Final Repository-wide Search and Replace
    - [ ] Perform a final case-insensitive search for "PresubmitCheck" to ensure no instances remain.
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Infrastructure & Documentation' (Protocol in workflow.md)
