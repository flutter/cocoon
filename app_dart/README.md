# Dart backend for cocoon

This folder contains a Dart based backend for Cocoon.

## Building and running

### Prerequisites

* Install the Google Cloud Developer Tools Command Line Interface
([`gcloud`](https://cloud.google.com/sdk/docs/quickstarts)). Then initialize it
and authenticate yourself by running:

```sh
gcloud auth application-default login
gcloud init
```
* [Install Flutter](https://flutter.dev/docs/get-started/install )
```sh
export PATH="$PATH":"path/to/flutter/bin/"
flutter upgrade
flutter pub get
export PATH="$PATH":"path/to/flutter/bin/cache/dart-sdk/bin/"
```

* Set the GOOGLE_CLOUD_PROJECT Environment Variable

```sh
export GOOGLE_CLOUD_PROJECT=flutter-dashboard
```

### Running the tests

```sh
$ dart test
```

### Running codegen

#### JSON

To update the JSON serialization generated code, run:

```sh
$ dart run build_runner build
```

Any updates should be checked into source control.

#### Protobuf

To update the Protocol Buffer generated code:

1. Activate and run protofu

   ```shell
   dart pub global activate protofu
   protofu
   ```

2. Format

   ```shell
   dart format .
   ```

3. Remove the unused generated files:

   ```shell
   find . -regex '.*\.\(pbjson\|pbserver\)\.dart' -delete
   ```

   or

   ```shell
   find -E . -regex '.*(pbserver|pbjson)\.dart'  -delete
   ```

   (you can remove the `*.pbenum.dart` files too, except for protobuffers that actually define enums,
   like `build_status_response.proto`)

### Generating cloud datastore indexes

To update the indexes in the App Engine project, run:

```sh
$ gcloud datastore indexes create index.yaml
```

### Local development

#### Using physical machine

* Starting server

```sh
dart run tool/local_server.dart
```

If you see Serving requests at 0.0.0.0:8080 the dev server is working.

#### Using Docker

* Running a local development instance

Once you've installed Docker and have the `docker` command-line tool in
your path, then you can use the following commands to build, run, stop,
and kill a local development instance.

```sh
# Build the docker image
$ docker build -t local .

# Start the local container, clearing the console buffer and tailing the logs
$ container_id="$(docker run -d -p 8080:8080 local)" && \
    clear && \
    printf '\e[3J' && \
    docker logs $container_id -f

# Stop the local Docker container
$ docker container ls|grep local|tr -s ' '|cut -d' ' -f1|xargs docker container stop

# Remove the local Docker image
$ docker images|grep local|tr -s ' '|cut -d' ' -f3|xargs docker rmi -f
```

* ssh into instance

```sh
$ docker exec -it <container name> /bin/bash
```

### Deploying a release to App Engine

#### [Auto-deploy](go/cocoon-cloud-build#auto-deploy)
Cocoon auto deployment has been set up via
[Google Cloud Build](https://console.cloud.google.com/cloud-build/triggers?project=flutter-dashboard)
daily on Workdays.

#### [Manual-deploy(go/cocoon-cloud-build#manual-deploy)

* Using the cloud build

This is easy to deploy if you simply want a new version based on
the latest commit. Open
[Cloud Build dashboard](https://console.cloud.google.com/cloud-build/triggers?project=flutter-dashboard)
and click run in the push-master trigger ([example](https://screenshot.googleplex.com/4DDy4XdVQxMKqCd))

* Using a cocoon checkout
Let `PROJECT_ID` be the Google Cloud Project ID and `VERSION` be the version you're deploying to App Engine. Visit
https://console.cloud.google.com/appengine/versions?project=flutter-dashboard
for the list of current versions.

```sh
$ dart dev/deploy.dart --version version-$(git rev-parse --short HEAD) --project flutter-dashboard
```

The deploy script will build the Flutter project and copy it over for deployment.
Then it will use the Google Cloud CLI to deploy the project to AppEngine.

For more options run:

```sh
$ dart dev/deploy.dart --help
```
