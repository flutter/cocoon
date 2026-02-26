# Specification: Rename PresubmitCheck to PresubmitJob

## Overview
This track aims to standardize the naming of Flutter's presubmit CI tasks. The current term "PresubmitCheck" will be replaced with "PresubmitJob" across all systems to align with common industry terminology and internal preferences. This is a comprehensive refactor that follows a "Clean Break" strategy, immediately replacing all instances without maintaining legacy aliases.

## Functional Requirements
- **Codebase Refactor:**
  - Rename all classes, functions, variables, and constants from `PresubmitCheck` (and its variants like `presubmit_check`, `presubmitCheck`) to `PresubmitJob` (e.g., `PresubmitJob`, `presubmit_job`, `presubmitJob`).
  - Target packages: `app_dart`, `auto_submit`, `dashboard`, `packages/cocoon_common`.
- **Infrastructure & Configuration:**
  - Update configuration keys in `app.yaml`, `config.yaml`, `.ci.yaml`, and any other YAML/JSON configuration files.
  - Ensure any Pub/Sub topic names or Cloud Build configuration references are updated if they contain "PresubmitCheck".
- **Public & Internal APIs:**
  - Update REST and gRPC API field names and endpoints.
  - Update protocol buffer definitions (`.proto`) and their generated code.
- **Data Persistence:**
  - Update Firestore collection names or document fields that store presubmit check data.
  - (Note: This may require a data migration script if live data exists).
- **Documentation:**
  - Update all `README.md` files, inline comments, and project documentation in the `docs/` and `conductor/` directories.

## Non-Functional Requirements
- **Consistency:** Ensure the rename is applied consistently across all layers (Frontend, Backend, Infrastructure).
- **Maintainability:** Standardizing the naming improves code readability for new and existing contributors.

## Acceptance Criteria
- [ ] No instances of the string "PresubmitCheck" (case-insensitive) remain in the codebase, excluding historical logs or external dependencies.
- [ ] The `dashboard` successfully displays "Presubmit Job" details instead of "Presubmit Check".
- [ ] `app_dart` and `auto_submit` services successfully process "PresubmitJob" events and configurations.
- [ ] All automated tests (unit and integration) pass with the new naming.
- [ ] Infrastructure deployments (Cloud Build, App Engine) function correctly with updated configuration keys.

## Out of Scope
- Renaming legacy logs in BigQuery (historical data).
- Renaming external LUCI/Buildbucket fields that are not controlled by the Cocoon project.
