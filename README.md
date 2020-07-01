Cocoon is a Dart App Engine custom runtime (backend) with a frontend
of Flutter apps (build and repository dashboard) and Angular 2 Dart
(performance dashboard) apps. Cocoon coordinates and aggregates the
results of [flutter/flutter](https://github.com/flutter/flutter)
builds. It is not designed to help developers build Flutter apps.
Cocoon is not a Google product.


# Using Cocoon

## Agents

The dashboard has a page showing [the status of all our current
agents](https://flutter-dashboard.appspot.com/#/agents).

### Creating an agent

To create an agent in the dashboard, it needs an `agentId` and a list
of capabilities (comma delimited). Clicking the "Create Agent" button
will show a dialog for creating an agent.

> An example of a valid agent would be `agentId`=`bot-with-devices` and
> `capabilities`=`has-android-phone,has-iphone`.

The dialog returns returns an authentication token, and prints it to
the console. This token is not stored, so copy it immediately and add
it to the agent's configuration file. If the token is lost or
compromised, authorize the agent to generate a new token.

### Authorizing an agent

Click on the dropdown for the agent, and click authorize agent. This
will print a new generated token to the console.

This command invalidates any previously issued authentication tokens
for the given agent. Only one authentication token is valid at any
given moment in time. Therefore, if the agent is currently using a
previously issued token its API requests will be rejected until it
switches to using the newly created token.

## Forcing a refresh from GitHub

The server is driven by commits made to
https://github.com/flutter/flutter repo. It periodically syncs new
commits. If you need to manually force a refresh, query
`https://flutter-dashboard.appspot.com/api/refresh-github-commits`.
You will need to be authenticated with Cocoon to do this.


# Developing Cocoon

Cocoon has several components:

* A server, which coordinates everything. This is a Dart App Engine
  application. If you have never used that before, you may want to
  [peruse the samples for Dart App
  Engine](https://github.com/dart-lang/appengine_samples). The server
  is found in `[app_dart](app_dart/)`.

* An agent, a Dart program that runs on test hosts, each of which have
  a test device. Our "devicelab" consists of computers with devices
  that are running agents and talking to the server to get tasks to
  run (e.g. a benchmark). The agent is found in `[agent](agent/)`.

* A Flutter app (generally used as a Web app) for the build and agent
  dashboards. The dashboard is found in `[app_flutter](app_flutter/)`.

* An [Angular 2 for
  Dart](https://angular.io/docs/dart/latest/quickstart.html) Web app
  for the performance dashboard. We intend to reimplement this in the
  Flutter app eventually. The performance dashboard is found in
  `[app](app/)`.

Cocoon creates a _checklist_ for each Flutter commit. A checklist is
made of multiple _tasks_. Tasks are _performed_ by _agents_. An agent
is a computer _capable_ of running a subset of tasks in the checklist.
To perform a task an agent _reserves_ it in Cocoon. Cocoon issues
tasks according to agents' _capabilities_. Each task has a list of
_required capabilities_. For example, a task might require that a
physical Android device is attached to an agent. It then lists
"has-physical-android-phone" capability as required. Multiple agents
may share the same capability. Cocoon will distribute tasks amongst
agents. That's how Cocoon scales.


## Getting started

First, [set up a Flutter development
environment](https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md#developing-for-flutter).
This will, as a side-effect, provide you with a Dart SDK. Your life
will be easier if you add that (`.../flutter/bin/cache/dart-sdk/bin/`)
to your path.

To update the production server, you will need the [Google Cloud
SDK](https://cloud.google.com/sdk/docs/quickstarts). Since there is no
Dart SDK, we just use the command line tools.


## Developing the server

All the commands in this section assume that you are in the
`app_dart/` directory.

### Running a local dev server

This is useful for developing backend functionality locally. This
local dev server can be connected to the frontend applications by
running `dart dev/deploy.dart --project test --version test`, and
answering `N` when asked about deploying to App Engine. This will
build the frontend files and copy them to the directory from which the
server will serve them.

Set the environment variables `GCLOUD_PROJECT` and `GCLOUD_KEY`.
Running `dart bin/server.dart` will give more explanation on what
these values should be. You should also set `COCOON_USE_IN_MEMORY_CACHE`
to `true` as you typically don't have access to the remote redis
instance during local development.

If you see `Serving requests at 0.0.0.0:8080` the dev server is working.

To develop and test some features, you need to have a local service 
account(key.json) with access to the project you will be connecting to.

If you work for Google you can use the key with flutter-dashboard project
via [internal doc](https://g3doc.corp.google.com/company/teams/flutter/cocoon/local_run.md?cl=head).

### Building the server for deployment

To run tests, build the app, and provide instructions for deploying to
Google App Engine, run this command:

```sh
dart dev/deploy.dart --project {PROJECT} --version {VERSION}
```

You can test the new version by accessing
`{VERSION}-dot-flutter-dashboard.appspot.com` in your browser. If the
result is satisfactory, the new version can be activated by using the
Cloud Console UI:
<https://pantheon.corp.google.com/appengine/versions?project=flutter-dashboard&serviceId=default>

#### Optional flags

`--profile`: Deploy a profile mode of `app_flutter` application for debugging purposes.


## Developing the dashboard

The dashboard application will use dummy data when it is not connected
to the server, so it can be developed locally without a dev server.

To run the dashboard locally, go into the `app_flutter` directory and
run `flutter run -d web`. The dashboard will be served from localhost
(the exact address will be given on the console); copy the URL into
your browser to view the application. (The dashboard should also be
able to run on non-Web platforms, but since the Web is our main target
that is the one that should generally be used for development.)

You may need to run `flutter config --enable-web` to enable Web
support if you haven't done so in the past.

You can run `flutter packages upgrade` to update the dependencies.
This may be necessary if you see a failure in the dependencies.

