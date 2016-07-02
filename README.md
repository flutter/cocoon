Cocoon is a hybrid Go App Engine (backend) and an Angular 2 Dart (client) app
used to coordinate and aggregate the results of Flutter's builds. It is not
designed to help developers build Flutter apps. More importantly, *Cocoon is not
a Google product*.

# Developing cocoon

* Learn [App Engine for Go](https://blog.golang.org/the-app-engine-sdk-and-workspaces-gopath)
* Learn [Angular 2 for Dart](https://angular.io/docs/dart/latest/quickstart.html)
* Create `$GOPATH/src` where `$GOPATH` can be anywhere
* `git clone` this repository into `$GOPATH/src` so that you have `$GOPATH/src/cocoon`
* Install Google App Engine for Go
* Install Go SDK
* Install Dart SDK
* Consider installing Atom
  * Consider installing `dartlang` for Atom
  * Consider installing `go-plus` for Atom

# Running local dev server

The following command will start a local Go App Engine server and a Dart pub
server.

```sh
cd app
pub get
dart bin/dev_server.dart
```

Once the log messages quiet down you should be able to open http://localhost:8080
and see the status dashboard backed by a fake local datastore.

# Building Cocoon for deployment

The following command will run tests and build the app, and provide instructions
for deploying to Google App Engine.

```sh
cd app
bin/build_and_test.sh
```

# Design

Cocoon creates a _checklist_ for a Flutter commit. A checklist is made of
multiple _tasks_. Tasks are _performed_ by _agents_. An agent is a computer
_capable_ of running some tasks. To perform a task an agent _checks out_ a task
(reserves it) from Cocoon. Cocoon issues tasks according to agents'
_capabilities_. An agent advertises its capabilities by listing them in the
check out request. Each task has a list of _required capabilities_. For example,
a task might require that a physical Android device is attached to an agent. It
then lists "has-physical-android-phone" capability as required. Multiple agents
may share the same capability. Cocoon will distribute tasks amongst agents,
thus scaling the build process.
