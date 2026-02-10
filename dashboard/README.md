# Flutter Dashboard

For how to use the app, see the [user guide](USER_GUIDE.md)

## Set up

- Install [Flutter](https://docs.flutter.dev/get-started/install), or use an existing checkout if a Flutter developer
- (Optional) Install [Firebase CLI](https://firebase.google.com/docs/flutter/setup)

## Running locally

It is possible to run a simulation of the UI locally with fake data:

```sh
# Launches Chrome
flutter run -d chrome --web-port=8080 --web-define=description=Dashboard --web-define=projectName=Dashboard

# Starts a web server, bring your own browser instance
flutter run -d web-server --web-port=8080 -web-define=description=Dashboard --web-define=projectName=Dashboard
```

NOTE: Must run on port 8080[^8080] for authentication to work.

[8080]: Google employees: See [GCP > Client ID for Web App](https://console.cloud.google.com/auth/clients/308150028417-vlj9mqlm3gk1d03fb0efif1fu5nagdtt.apps.googleusercontent.com?e=-13802955&invt=AbvvHw&mods=logs_tg_prod&project=flutter-dashboard).

## Tests

Most tests can be run locally:

```sh
flutter test
```

### Updating Goldens

Some tests take and compare UI screenshots which will change over time. For compatibility reasons, only a Linux host is supported.

```sh
flutter test --update-goldens
```

The GitHub workflow that checks this should upload the golden failures as annotations
to review. You can also verify locally with:

```shell
gh act \
  -b \ # BIND your folder instead of copying - this is how you get failures/ out.
  --container-architecture linux/amd64 \ # required for mac
  --container-options="--tty" \
  --workflows ".github/workflows/dashboard_tests.yaml"
```

To just accept the changes:
```shell
gh act \
  -b \ # BIND your folder instead of copying - this is how you get updates out.
  --env UPDATE_GOLDENS=true \            # Use this to pass --update-goldens.
  --container-architecture linux/amd64 \ # required for mac
  --container-options="--tty" \
  --workflows ".github/workflows/dashboard_tests.yaml"
```
