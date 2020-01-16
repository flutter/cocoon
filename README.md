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
* Learn [Angular 2 for Dart](https://angular.io/docs/dart/latest/quickstart.html) - *Only for performance dashboard*

# Running local dev server

This is useful for developing backend functionality locally. This local dev
server can be connected to the frontend applications by running `dart dev/deploy.dart --project test --version test`
and answer `N` to deploying to AppEngine. This will build the frontend files
and copy them to the directory the server will serve them out of.

Set the environment variables `GCLOUD_PROJECT` and `GCLOUD_KEY`. Running the
following command will give more explaination on what these values should be.

[Make sure to create a service account in the GCP dashboard](https://pantheon.corp.google.com/iam-admin/serviceaccounts?project=flutter-dashboard&supportedpurview=project)

`cd app_dart && dart bin/server.dart`

If you see `Serving requests at 0.0.0.0:8080` the dev server is working.

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

# Infra Tools

[Infra Agent Dashboard](https://flutter-dashboard.appspot.com/#/agents)

## Creating an agent

To create an agent in the dashboard, it needs an `agentId` and a list of
capabilities (comma delimited). Clicking the floating action button will show
a create agent dialog.

An example of a valid agent would be `agentId`=`bot-with-devices` and 
`capabilities`=`has-android-phone,has-iphone`.

*IMPORTANT*: This returns an authentication token, and prints it to the console. 
Cocoon does not store the token, so copy it immediately and add it to the 
agent's configuration file. If the token is lost or compromised, authorize the
agent to generate a new token.

## Authorizing an agent

Click on the dropdown for the agent, and click authorize agent. This will
print a new generated token to the console.

*IMPORTANT*: See the *IMPORTANT* note in "Creating an agent". Also, note that
this command invalidates any previously issued authentication tokens for the
given agent. Only one authentication token is valid at any given moment in time.
Therefore, if the agent is currently using a previously issued token its API
requests will be rejected until it switches to using the newly created token.

## Forcing a refresh from GitHub

Cocoon is driven by commits made to https://github.com/flutter/flutter repo. It
periodically syncs new commits. If you need to manually force a refresh, query
`https://flutter-dashboard.appspot.com/api/refresh-github-commits`.
