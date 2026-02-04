# Product Guidelines - Cocoon

## Prose Style
*   **Technical and Direct:** Documentation and user-facing messages must be clear, precise, and efficient. Avoid jargon where a simpler technical term suffices, but maintain a high level of technical accuracy appropriate for infrastructure and software engineers.
*   **Action-Oriented:** Focus on providing the information necessary for users to understand build statuses and resolve CI issues quickly.

## Design Principles
*   **Expert-Centric Information Density:** The dashboard should prioritize utility and information density. Expert users (Release Engineers, EngProd) need to see a broad overview of tree health, including multiple commits and task results, on a single screen to identify patterns and regressions.
*   **Layered Complexity:** While the primary view should be dense and informative, use visual cues (like color-coding and iconography) to provide immediate high-level status (Red/Green/Yellow). Detailed logs and historical data should be easily accessible but secondary to the main grid.
*   **Performance First:** Given the volume of data in Flutter's CI, the UI must remain responsive. Lazy loading, efficient data fetching, and minimal re-renders are critical for a smooth monitoring experience.

## Reliability & Error Handling
*   **Resilience through Automation:** The system must automatically handle transient failures (e.g., GitHub API timeouts or LUCI build-bucket flakes) using robust retry logic to maintain high data fidelity.
*   **Graceful Degradation:** The dashboard must remain functional even if partial data is missing. If a specific service (like BigQuery or a specific LUCI project) is down, the UI should clearly indicate the limitation while still serving available information.
*   **Verbose Debugging Context:** When system errors occur, provide enough technical context (trace IDs, error codes, and source references) in logs and internal UI views to allow EngProd to diagnose the root cause without significant investigation.
