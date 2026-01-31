# Product Definition - Cocoon

## Initial Concept
Cocoon is the CI coordination and orchestration system for the Flutter project. It serves as the orchestrator for Flutter's continuous integration pipelines, providing both the backend logic for scheduling and tracking builds and the frontend dashboards for monitoring repository health. It acts as the bridge between GitHub (source control) and LUCI, managing the lifecycle of commits, pull requests, and build artifacts. It consists of a backend orchestrator, an autosubmission bot, and a frontend dashboard for visualization.

## Target Users
*   **Flutter Framework and Engine Engineers:** Use Cocoon to monitor test results and maintain tree health.
*   **Flutter Release Engineers:** Depend on Cocoon to manage the release process for stable and beta builds, including monitoring and testing.
*   **Flutter EngProd (Engineering Productivity) Engineers:** Manage the infrastructure integrations (GitHub, LUCI, Pub/Sub) and monitor the overall health of the CI system.

## Goals & Outcomes
*   **Maintain Build Stability:** Ensure the health and stability of the Flutter framework and engine repositories.
*   **Actionable Visibility:** Provide clear, real-time dashboards for tracking build statuses, test results, and performance metrics.
*   **Workflow Automation:** Improve developer velocity by automating routine Pull Request tasks like merging and reverting via the auto-submit bot.
*   **Reliable Integration:** Seamlessly coordinate between GitHub webhooks, LUCI build bots, and Google Cloud services.

## Key Features
*   **CI Orchestration:** Automates the scheduling and tracking of LUCI builds for the Flutter framework and engine.
*   **Tree Status Dashboard:** A Flutter-based web application that provides a visual overview of build health across various commits and branches.
*   **Auto-submit Bot:** Handles automated pull request management, including label-based merges, reverts, and validation checks.
*   **GitHub Integration:** Robust handling of GitHub webhooks to sync commits, manage check runs, and report build statuses back to PRs.
*   **Unified Data Store:** Leverages Cloud Firestore and BigQuery for tracking build history, metrics, and CI health trends.
