This document covers fundamentals of Flutter cocoon, including frontend [dashboard](https://flutter-dashboard.appspot.com/) and backend APIs/Cronjobs.

# Terminology

* DeviceLab
  * The hardware lab
* Dashboard
  * The [web UI](https://flutter-dashboard.appspot.com) that aggregates Flutter CI build results and benchmarks
* Agent
  * One of the real/virtual machines that runs build tasks. Typically an agent  in the devicelab will have a mobile device attached to it.
* CLI
  * One command line interface accessible on the dashboard
* Cronjob
  * Cronjob implemented in [app engine](https://pantheon.corp.google.com/appengine/cronjobs?project=flutter-dashboard)

# Backend
## APIs
### /api/authorize-agent
This API authorizes an existing DeviceLab agent for cocoon, and at the same time invalidates any previously issued authentication tokens for the given agent. It is called via the CLI.
#### detail
* Authorize the agent record based on input `AgentID`.
  * Re-generates a 16-digit auth_token, which is used in `cocoon/agent/config.yaml`
  * Updates the above token’s hash in datastore
#### usage
* Go to build dashboard
* Chrome Dev Tools > Console
* `cocoon.authAgent(['-a', 'agentID])`
  * agentID follows `flutter-devicelab-<platform>-<number>`

### /api/create-agent
This API creates an agent for cocoon, and is called via the CLI.
#### detail
* Create the agent record based on inputs `AgentID` and `Capabilities`.
  * Generates a 16-digit auth_token, which is used in `cocoon/agent/config.yaml`
    * Cocoon does not store the token, so copy it immediately and add it to the agent's configuration file
  * Saves the above token’s hash in datastore
#### usage
* Go to build dashboard
* Chrome Dev Tools > Console
* `cocoon.createAgent(['-a', 'agentID, '-c', 'Capabilities'])`
  * agentID follows `flutter-devicelab-<platform>-<number>`
  * Capabilities: `linux/android, linux, linux-vm, mac/ios, mac, mac/android`, etc.

### /api/get-log
This API fetches log chunks and append them together from datastore based on the task key.
#### usage
* Frontend dashboard calls this API when people click task button to view logs

### /api/append-log
This API saves log chunks to datastore based on task key.
#### usage
* Cocoon agents call this API when executing build tasks

### /api/push-build-status-to-github
This API first fetches the latest build status from datastore, and then compares it with the latest status of every open pull request. If different, this API updates the status both in Github and datastore.
#### detail
* Fetch the latest build status
* Iterate every open PR in github
  * Compare the status in each PR with the latest build status
  * If different, then update the status in each PR
  * Batch-update status in datastore
#### usage
* Directly call via a cronjob in app engine every 1 min

### /api/refresh-cirrus-status
This API refreshes cirrus statuses from Github to flutter dashboard (frontend) every 2 mins via a cronjob.
#### detail
* Fetch latest 15 cirrus tasks, corresponding to top 15 commits
* For each cirrus task/commit, call [Github check-runs API](https://developer.github.com/v3/checks/runs/#list-check-runs-for-a-specific-ref) to fetch CI tasks statuses 
  * Each cirrus task/commit consists of 50+ sub tasks
* Determine cirrus task status based on statuses and conclusions for all sub tasks
  * Status: queued, in_progress, completed
  * Conclusion: success, failure, neutral, cancelled, timed_out, action_required
  * Logic
    * If no sub task returns => New
    * Else if any ‘failure’, ‘cancelled’, ‘timed_out’, or ‘action_required’ => Failed
    * Else if any ‘in_progress’, ‘queued’ => In Progress
    * Else => Succeeded
#### usage
* Directly call via a [cronjob](https://pantheon.corp.google.com/appengine/cronjobs?project=flutter-dashboard) in app engine every 2 min

### /api/refresh-github-commits
This API fetches commit list from Github and checks if any not in datastore yet. If any, then inserts those to both datastore and bigquery.
#### usage
* Directly call via a [cronjob](https://pantheon.corp.google.com/appengine/cronjobs?project=flutter-dashboard) in app engine every 1 min

### /api/update-agent-health
This API updates Agent health status continuously to both datastore and bigquery. Datastore keeps the latest status while bigquery keeps the historical data.
#### usage
* Cocoon Agent calls this API when running in CI mode. Before executing any task, Agent does pre-health check and then calls this API

### /api/update-benchmark-targets
This API updates benchmark values for TimeSeries based on TimeSeriesKey. It first makes sure the targeted TimeSerries exists in datastore, and then updates its goal and baseline with what provided.
#### usage
* In dashboard benchmark page, one calls this API by view historical data - which shows the update option at the same time.

### /api/update-task-status
This API updates task status when finished.
#### detail
* Checks to make sure task and its corresponding commit exist in datastore
* Checks task status
  * If succeeded => update datastore and bigquery
  * If failed
    * If Attempts > maxRetries => update datastore and bigquery
    * Otherwise => reset task to be picked up by Agents
#### usage
Cocoon Agent calls this API when running in CI mode whenever finishing running tasks.

## Cronjobs
### /api/check-waiting-pull-requests
* check for mergeable commits waiting for the tree to go green	
* every 5 minutes (GMT)	
### /api/push-build-status-to-github
* sends build status to GitHub to annotate PRs and commits	
* every 1 minutes (GMT)	
### /api/push-engine-build-status-to-github
* sends build status to GitHub to annotate engine PRs and commits	
* every 2 minutes (GMT)
### /api/refresh-chromebot-status
* refresh chromebot build status	
* every 3 minutes (GMT)	
### /api/refresh-cirrus-status
* refresh github CI status (cirrus)	
* every 2 minutes (GMT)	
### /api/refresh-github-commits
* refresh commits from GitHub	
* every 1 minutes (GMT)	
### /api/update-agent-health-history
* insert agent health status to bigquery	
* every 1 minutes (GMT)	
### /api/vacuum-clean
* clean up stale datastore records
* Every 10 minutes
