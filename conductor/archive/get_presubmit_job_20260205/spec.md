# Specification: Presubmit Job Details API

## Overview
This track involves implementing a new API endpoint in the `app_dart` backend service to provide detailed information about a specific presubmit job. The dashboard will use this API to display the history and status of all jobs for a given check run.

## Functional Requirements
- **Endpoint:** `/api/public/get-presubmit-jobs`
- **Method:** GET
- **Parameters (Mandatory):**
    - `check_run_id`: The unique identifier for the GitHub Check Run.
    - `job_name`: The name of the job (e.g., "Linux Device Doctor").
- **Backend Service:** `app_dart`.
- **Data Source:** Firestore.
- **Response Format:** JSON (Top-level array).
- **Response Data:**
    - An array of `PresubmitJobResponse` objects, sorted in descending order by `attempt_number`.
    - Each `PresubmitJobResponse` object MUST contain:
        - `attempt_number`: Integer
        - `job_name`: String
        - `creation_time`: Timestamp (ISO 8601 or ms since epoch)
        - `start_time`: Timestamp
        - `end_time`: Timestamp
        - `status`: String
        - `summary`: String (A brief diagnostic summary or link to logs)

## Error Handling
- **400 Bad Request:** Returned if mandatory parameters are missing.
- **404 Not Found:** Returned if the job or its job history is not found.
