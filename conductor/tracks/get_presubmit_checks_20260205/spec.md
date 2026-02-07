# Specification: Presubmit Check Details API

## Overview
This track involves implementing a new API endpoint in the `app_dart` backend service to provide detailed information about a specific presubmit check. The dashboard will use this API to display the history and status of all checks for a given check run.

## Functional Requirements
- **Endpoint:** `/api/get-presubmit-checks`
- **Method:** GET
- **Parameters (Mandatory):**
    - `check_run_id`: The unique identifier for the GitHub Check Run.
    - `check_name`: The name of the check (e.g., "Linux Device Doctor").
- **Backend Service:** `app_dart`.
- **Data Source:** Firestore.
- **Response Format:** JSON (Top-level array).
- **Response Data:**
    - An array of `PresubmitCheckResponse` objects, sorted in descending order by `attempt_number`.
    - Each `PresubmitCheckResponse` object MUST contain:
        - `attempt_number`: Integer
        - `build_name`: String
        - `creation_time`: Timestamp (ISO 8601 or ms since epoch)
        - `start_time`: Timestamp
        - `end_time`: Timestamp
        - `status`: String
        - `summary`: String (A brief diagnostic summary or link to logs)

## Error Handling
- **400 Bad Request:** Returned if mandatory parameters are missing.
- **404 Not Found:** Returned if the check or its check history is not found.
