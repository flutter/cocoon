# Flutter Dashboard User Guide

## Build dashboard

The build page is accessible at https://flutter-dashboard.appspot.com/#/build.

Build statuses of commits on this page are sync'ed with the flutter/flutter repo.

### Tree Closures

The top navigation bar indicates the current tree status. If the tree is closed,
at least one test has failed against the top of tree and flutter/flutter is
currently not accepting new commits. Check on Discord [#tree-status](https://discord.com/channels/608014603317936148/613398423093116959)
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
including Cirrus, LUCI, and DeviceLab. DeviceLab and Cirrus test every commit
that goes into the `master` branch. However, LUCI may skip commits when they
come in too fast.

Flutter infra prioritizes running tasks against the most recent commits. This
leads to some tasks never being run on a commit as the test coverage was
provided from a more recent commit.

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

See [backend branching support for flutter/flutter](../app_dart/README.md#branching-support-for-flutter-repo).

### There's a lot of boxes! Can I filter them?

Yes, click the settings cog in the top right for various filtering options.

Some options available include: authors, commit names, and platform run on.
PRs welcome for new filtering options!

If you're interested in a larger data analysis, the Flutter Infra Team pushes
this data to BigQuery.
