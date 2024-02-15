# Flutter Dashboard User Guide

The dashboard is generated based on a repo's [.ci.yaml](../CI_YAML.md).

## Build dashboard

The build page is accessible at https://flutter-dashboard.appspot.com/#/build.

Build statuses of commits on this page are sync'ed with most repos in https://github.com/flutter

### Tree Closures

The top navigation bar indicates the current tree status. If the tree is closed,
at least one test has failed against the top of tree and flutter/flutter is
currently not accepting new commits. Check on Discord [#tree-status](https://discord.com/channels/608014603317936148/613398423093116959)
for discussion about tree closures.

Tree closures occur when the latest results for a test have returned as
failing. Logs are found by clicking a task box then clicking "view logs."


### Why is a task stuck on "new task" status?

The dashboard aggregates build results from multiple build environments,
including LUCI and DeviceLab. Due to limited capacity to run tests on
physical devices, some tests may be batched (run for several commits).

Flutter infra prioritizes running tasks against the most recent commits. This
leads to some tasks never being run on a commit as the test coverage was
provided from a more recent commit.

### Why do some tasks have an exclamation point?

Tasks with exclamation points indicate a task that has been run multiple times.
This indicates extra capacity used for this task. In some cases, this is an
infra issues. If it's common for a task column to be filled with green tasks
with exclamation marks, it indicates that task is flaky.

### How do I view results for a release branch?

**TODO(chillers): Update this when release branches are supported by cocoon scheduler**

Visit https://ci.chromium.org/p/flutter and click the link for the repo and release channel.

### There's a lot of boxes! Can I filter them?

Yes, click the settings cog in the top right for various filtering options.

Some options available include: authors, commit names, and platform run on.
PRs welcome for new filtering options!

If you're interested in a larger data analysis, the Flutter Infra Team pushes
this data to BigQuery.
