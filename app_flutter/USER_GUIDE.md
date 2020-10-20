# Flutter Dashboard User Guide

## Build dashboard

The build page is accessible at https://flutter-dashboard.appspot.com/#/build.
This page reports the build statuses of commits to the flutter/flutter repo.

### Tree Closures

The top navigation bar indicates the current tree status. If the tree is closed,
a test has failed against the top of tree and flutter/flutter is currently not
accepting new commits. Check on Discord [#tree-status](https://discord.com/channels/608014603317936148/613398423093116959)
for discussion about tree closures.

Tree closures occur when the latests results for a test have returned as
failing. Logs are found by clicking a task box then clicking "Download Logs."

### Why am I not able to download logs?

Ensure that you are signed in to the app (top right).

Reach out on Discord [#hackers-infra](https://discord.com/channels/608014603317936148/608021351567065092)
to be added as an AllowListedAccount to Cocoon.

When the DeviceLab migrates to LUCI, logs will be available without sign in.

### Why is a task stuck on "new task" status?

The dashboard aggregates build results from multiple build environments,
including Cirrus, LUCI, and DeviceLab. While DeviceLab attempts to
tests every commit that goes into the `master` branch, other environments
may skip some commits. LUCI may skip commits when they come in too fast.

Flutter infra may skip running tests against a commit if there are passing
results from a more recent commit.

DeviceLab tests are eventually run against every commit to ensure benchmark
data is collected from every commit. This helps with triaging where performance
regressions started.

### Why are some tasks outlined instead of solid?

Outlined tasks indicate a task that is running experimentally. This can be for
a number of reasons:
  1. Validating a new test before it can block the tree
  2. A test has become extremely flaky

### Why do some tasks have an exclamation point?

Tasks with exclamation points indicate a task that has been run multiple times.
This indicates extra capacity used for this task. In some cases, this is an
infra issues. If it's common for a task column to be filled with green tasks
with exclamation marks, it indicates that task is flaky.

### How do I view results for a release branch?

Click the settings cog in the top right, and switch the branch via the dropdown.

If the branch is not in the list, it has not propagated to Cocoon's backend.

### There's a lot of boxes! Can I filter them?

Yes, click the settings cog in the top right for various filtering options.

Some options available include: authors, commit names, and platform run on.
PRs welcome for new filtering options!

If you're interested in a larger data analysis, the Flutter Infra Team pushes
this data to BigQuery.

## Performance dashboard

https://flutter-dashboard.appspot.com/benchmarks.html.

This dashboard loads a lot of data, and can take ~1 minute to get a response
from the backend.

### How do I update the baseline for a benchmark?

1. Ensure that you are signed in with an AllowListedAccount with Cocoon
2. Hover over top right corner of the benchmark graph of interest
3. Click the magnifying glass
4. A UI at the top will come down with a form to change baseline values

## Agent dashboard

Agent statuses are available at https://flutter-dashboard.appspot.com/#/agents.

A green agent is considered healthy and ready to receive new tasks to build. A
red agent is broken and does not receive new tasks.

The Flutter Infra oncall will look into bringing an agent back online.
