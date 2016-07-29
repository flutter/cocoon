# Cocoon Agent

An _agent_ runs on a computer and runs tests reserved for it by the Cocoon
backend. It may or may not have physical devices attached to it.

## Starting an agent

Agent has several subcommands:

`run` command runs a single task. Here's how you run it:

```sh
dart bin/agent.dart run --task-name={TASK_NAME}
```

It runs the task at the currently synced version of Flutter.

`ci` command runs the agent in _continuous integration_ mode. It continuously
asks the Cocoon backend for available tasks, syncs Flutter to the desired
revision and runs the task. Use it like this:

```sh
dart bin/agent.dart ci
```

## Setting up a Mac agent

Follow Flutter's [setup guide](https://flutter.io/setup/). Make sure Flutter
runs successfully for the kind of test scenarios you intend to use the agent
for. For example, if you plan to run tests on a real Android device, make sure
there _is_ an Android device attached, the Android SDK installed and you are
able to run one of the sample Flutter apps on the device.

## Agent configuration

### Creating agent and acquiring auth tokens

Pick a good ID for the agent. If there are existing agents performing the
same set of tasks give it the same ID with a different number. For example, if
there are "mac1" and "mac2", and you are adding another Mac build agent, call it
"mac3". If you are adding an agent that doesn't fit within any of the existing
groups, pick a new ID and start numbering beginning from 1, e.g. "linux1".

Read [Creating an agent](https://github.com/flutter/cocoon#creating-an-agent)
about how to create the agent and acquire an authentication token to connect it
to Cocoon.

To authenticate with Firebase read go/flutter-cocoon.

At the end of this exercise you should have an agent ID, a Cocoon auth token
and a Firebase auth token.

### config.yaml

You will need to enter information acquired in the previous step into a
`config.yaml` file. See the
[sample config file](https://github.com/flutter/cocoon/blob/master/agent/config.sample.yaml)
that documents all parameters in detail.
