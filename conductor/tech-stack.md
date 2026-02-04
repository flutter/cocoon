# Tech Stack - Cocoon

## Core Technologies
*   **Primary Language:** Dart (SDK 3.x+)
*   **Frontend Framework:** Flutter Web (located in `dashboard/`)
*   **Backend Runtime:** Dart App Engine (Custom Runtime)
    *   `app_dart`: Raw Dart I/O and `package:appengine`.
    *   `auto_submit`: Uses `package:shelf` and `package:shelf_router`.
*   **Infrastructure:** Google Cloud Platform (GCP)
    *   **App Engine (Flexible):** Hosting for both backend services.
    *   **Cloud Build:** CI/CD for deploying Cocoon services.
    *   **Pub/Sub:** Messaging for decoupling GitHub webhooks and LUCI build updates.
    *   **Secret Manager:** Management of sensitive keys (GitHub tokens, webhook secrets).
    *   **Memorystore (Redis):** Caching layer using `package:neat_cache`.

## Data Storage & Analytics
*   **Cloud Firestore:** Primary NoSQL database for tracking commits, tasks, and tree status.
*   **BigQuery:** Data warehouse for CI metrics, performance tracking, and historical analysis.

## External Integrations
*   **GitHub API:** Interaction with GitHub via `package:github` and raw GraphQL queries for PR management and Checks API.
*   **LUCI (Layered Universal Continuous Integration):** gRPC/REST interaction to schedule and monitor builds via the BuildBucket API (using `packages/buildbucket-dart`).

## Project Architecture
*   **Monorepo Structure:** Managed as a Dart Workspace.
    *   `app_dart/`: Main CI orchestrator and backend API.
    *   `auto_submit/`: Automated PR management bot.
    *   `dashboard/`: Flutter Web frontend.
    *   `packages/`: Shared libraries and internal SDKs (`cocoon_common`, `buildbucket-dart`).
*   **Code Generation:** 
    *   `build_runner` for `json_serializable` (DTOs/Database models).
    *   `package:protobuf` for internal configuration (`.ci.yaml`) and BuildBucket interactions.