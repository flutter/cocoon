# Implementation Plan: Re-run Failed Jobs API for Unified Checkrun

## Phase 1: Research & Discovery [checkpoint: 41c1531]
- [x] Task: Analyze `LuciBuildService` and `BuildBucketClient` in `app_dart/lib/src/service` to identify re-run capabilities.
- [x] Task: Research `unified_check_run.dart` and `GetPresubmitChecks` handler to understand how jobs are linked to `check_run_id`.
- [x] Task: Identify the appropriate method for GitHub write access verification (check existing `app_dart` patterns).
- [x] Task: Conductor - User Manual Verification 'Research & Discovery' (Protocol in workflow.md)

## Phase 2: Individual Job Re-run API [checkpoint: 41e7db8]
- [x] Task: Create `app_dart/lib/src/request_handlers/rerun_failed_job.dart` handler.
- [x] Task: Implement `LuciBuildService.rescheduleBuildById` to trigger a re-run using `build_bucket_id`.
    - [x] Fetch build by ID from BuildBucket.
    - [x] Extract `PresubmitUserData` and `nextAttempt`.
    - [x] Call `reschedulePresubmitBuild`.
- [x] Task: Implement authorization check within the handler using `CheckrunAuthentication`.
- [x] Task: Write unit tests in `app_dart/test/request_handlers/rerun_failed_job_test.dart` (Success, 403 Forbidden, 400 Bad Request).
- [x] Task: Conductor - User Manual Verification 'Individual Job Re-run API' (Protocol in workflow.md)

## Phase 3: Bulk Re-run Failed Jobs API [checkpoint: d1aa10d]
- [x] Task: Create `app_dart/lib/src/request_handlers/rerun_all_failed_jobs.dart` handler.
- [x] Task: Implement logic in `UnifiedCheckRun.getLatestFailedChecks` to fetch all failed builds associated with a `check_run_id` from Firestore.
- [x] Task: Implement bulk re-run logic using `LuciBuildService.scheduleTryBuilds`.
- [x] Task: Write unit tests in `app_dart/test/request_handlers/rerun_all_failed_jobs_test.dart` (Multiple failures, No failures, 403 Forbidden).
- [x] Task: Conductor - User Manual Verification 'Bulk Re-run Failed Jobs API' (Protocol in workflow.md)

## Phase 4: Final Integration & Cleanup [checkpoint: f8b49d4]
- [x] Task: Register `/api/rerun-failed-job` and `/api/rerun-all-failed-jobs` in `app_dart/lib/server.dart`.
- [x] Task: Perform final integration tests using `packages/cocoon_integration_test` (if applicable) or manual verification via `curl`.
- [x] Task: Refactor authorization check to `ApiRequestHandler`.
- [x] Task: Split `checkWritePermissions` to `isUserGoogleEmployee` and `hasUserGithubWritePermission`.
- [x] Task: Revert `RerunAllFailedJobs`, rename `checkRunId` to `guardCheckRunId` in `reInitializeFailedChecks`, implement `reInitializeFailedJob`, and update parameters.
- [x] Task: Remove `_scheduler.findPullRequestCached` call in `RerunAllFailedJobs`.
- [x] Task: Add `pull_request_num` field to `PrCheckRuns` and implement `findPullRequestForPullRequestNum`.
- [x] Task: Update `pull_request_num` in `updatePullRequestForSha`.
- [x] Task: Add `findPullRequestCachedForPullRequestNum` to `Scheduler`.
- [x] Task: Add `githubService` to `Scheduler` constructor and cache PRs in `findPullRequestCachedForPullRequestNum`.
- [x] Task: Update handlers to use `owner`, `repo`, and `pr` and implement `getLatestPresubmitGuardByPullRequestNum`.
- [x] Task: Default `owner` and `repo` to 'flutter' in handlers.
- [x] Task: Fix `validate cocoon ci.yaml generates jspb` unit test.
- [x] Task: Conductor - User Manual Verification 'Final Integration & Cleanup' (Protocol in workflow.md)
