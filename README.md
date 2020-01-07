Cocoon is a Dart App Engine custom runtime (backend) with a frontend of Flutter
apps (build and repository dashboard) and Angular 2 Dart (performance dashboard)
apps. Cocoon coordinates and aggregates the results of [flutter/flutter](https://github.com/flutter/flutter) 
builds. It is not designed to help developers build Flutter apps. More 
importantly, *Cocoon is not a Google product*.

# Developing cocoon

* Install Google Cloud SDK
* Install Flutter
* Learn [App Engine for Dart](https://github.com/dart-lang/appengine_samples)
* Learn [Flutter](https://flutter.dev/docs/get-started/codelab)
* Learn [Angular 2 for Dart](https://angular.io/docs/dart/latest/quickstart.html)

# Running local dev server

TODO: Port the Go dev server to work with the Dart AppEngine system. https://github.com/flutter/flutter/issues/45410

# Testing Angular changes with production data

Run `dart bin/dev_server.dart` with the option go/flutter-dev-server-auth. This will cause the dev
server to call the production servers for all API calls. This only works for testing Angular
changes. Changes in Go code require building and deploying the whole thing (see next section).

# Building Cocoon for deployment

The following command will run tests and build the app, and provide instructions
for deploying to Google App Engine.

```sh
cd app_dart
dart dev/deploy.dart --project {PROJECT} --version {VERSION}
```

You can test the new version by accessing `{VERSION}-dot-flutter-dashboard.appspot.com` in your
browser. If the result is satisfactory, the new version can be activated by using the Cloud Console
UI: https://pantheon.corp.google.com/appengine/versions?project=flutter-dashboard&serviceId=default

## Optional flags

`--profile`: Deploy a profile mode of `app_flutter` application for debugging purposes.

# Design

Cocoon creates a _checklist_ for each Flutter commit. A checklist is made of
multiple _tasks_. Tasks are _performed_ by _agents_. An agent is a computer
_capable_ of running a subset of tasks in the checklist. To perform a task an
agent _reserves_ it in Cocoon. Cocoon issues tasks according to agents'
_capabilities_. Each task has a list of _required capabilities_. For example,
a task might require that a physical Android device is attached to an agent. It
then lists "has-physical-android-phone" capability as required. Multiple agents
may share the same capability. Cocoon will distribute tasks amongst agents.
That's how Cocoon scales.

# In-browser CLI

*Accessible on on the [Angular Dart build dashboard](https://flutter-dashboard.appspot.com/old_build.html)*

Cocoon browser interface includes a small CLI. To access it open Chrome Dev
Tools > Console. Commands are entered directly into the console like this:

```javascript
cocoon.COMMAND([COMMAND_ARGS...])
```

The list of available commands is printed to the console when the page is
loaded.

## Creating an agent

The following command creates an agent with ID "bot-with-devices", and which has
two capabilities: "has-android-phone" and "has-iphone".

```javascript
cocoon.createAgent(['-a', 'bot-with-devices', '-c', 'has-android-phone', '-c', 'has-iphone'])
```

Agent ID is passed as option `-a`, and agent's capabilities are passed as one or
more `-c`.

*IMPORTANT*: This command returns an authentication token. Cocoon does not store
the token, so copy it immediately and add it to the agent's configuration file.
If the token is lost or compromised, use the "auth-agent" command below to
generate a new token.

## Authorizing an agent

The following commands generates an authentication token for an agent.

```javascript
cocoon.authAgent(['-a', 'bot-with-devices'])
```

*IMPORTANT*: See the *IMPORTANT* note in "Creating an agent". Also note that
this command invalidates any previously issued authentication tokens for the
given agent. Only one authentication token is valid at any given moment in time.
Therefore, if the agent is currently using a previously issued token its API
requests will be rejected until it switches to using the newly created token.

## Forcing a refresh from GitHub

Cocoon is driven by commits made to https://github.com/flutter/flutter repo. It
periodically syncs new commits. If you need to manually force a refresh, issue
the following CLI command:

```javascript
cocoon.refreshGithubCommits([])
```
