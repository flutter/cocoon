# Dart backend for cocoon

This folder contains a Dart based backend for Cocoon.

## Building and running

### Running codegen

To update the JSON serialization generated code, run:

```sh
$ pub run build_runner build
```

Any updates should be checked into source control.

### Generating cloud datastore indexes

To update the indexes in the App Engine project, run:

```sh
$ gcloud datastore indexes create index.yaml
```

### Running a local development instance

Once you've installed Docker and have the `docker` command-line tool in
your path, then you you can use the following commands to build, run, stop,
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

### Deploying a release to App Engine

Let _VERSION_ be the version you're deploying to App Engine. Visit
https://console.cloud.google.com/appengine/versions?project=flutter-dashboard
for the list of current versions.

```sh
$ gcloud app deploy \
    --project flutter-dashboard \
    --no-promote \
    --no-stop-previous-version \
    --version $VERSION
```
