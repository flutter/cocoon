# Flutter Dashboard

[User Guide](USER_GUIDE.md)

## Running for web locally

`flutter run -d chrome --web-port=8080`

Must run on port 8080 for Google Sign In to work since that is the
only enabled port for localhost.

## Running native app locally

`flutter run -d <macos|linux|windows>`

If you want to run a debug native app with production data, you can run it like so:

`flutter run -d <macos|linux|windows> -a --use-production-service`

If you want to run a release native app with fake data, use:

`flutter run -d <macos|linux|windows> --release -a --no-use-production-service`

[Unfortunately, there's no web equivalent for passing command line arguments yet]

You can also build a release AOT-compiled desktop app with `flutter build
<macos|linux|windows> --release` and then just run the app with the appropriate
argument.

## Style

### File organization

The `lib` directory is organized in subdirectories as follows:

* `lib/`: main.dart and top-level widgets (e.g. the build dashboard
  widget). Can import anything.

* `lib/widgets/`: Custom widgets used in this project. The files in
  this directory should import either the Flutter widgets package or
  the Flutter material package, and may import any local files except
  those that are directly in the top-level `lib/` directory (i.e.
  importing from `lib/logic/` et al is fine).

* `lib/state/`: States, objects that interface between widgets and the
  services. Files in this directory should not import any Flutter
  packages other than foundation, and should not import local files
  that relate to UI (e.g. those in `widgets/`).

* `lib/service/`: Services, objects that interface with the network.
  Files in this directory should not import any Flutter packages other
  than foundation, and should not import any local files from other
  directories.

* `lib/logic/`: Other code, mainly non-UI utility methods and data
  models. Files in this directory should not import any Flutter
  packages other than foundation, and should not import any local
  files from other directories.

The `test` directory should follow the same structure, with files
testing code from files in `lib` being in the parallel equivalent
directories.

### Imports

Imports in Dart files in this project should follow the rules
enforced by the `directives_ordering` lint described
[here](https://dart-lang.github.io/linter/lints/directives_ordering.html).

## Tests

### Updating Goldens

The build dashboard has a few custom render objects to optimize rendering of a large 2D array of rects.

The tests require a linux host to be updated:

```sh
flutter test --update-goldens
```

## Deploying

### Web

Cocoon has a daily Cloud Build trigger that will publish this to
https://flutter-dashboard-appspot.com.

### Playstore

#### Set up

Download signing key from Valentine (under dashboards@flutter.dev). Save to
`$HOME/upload-keystore.jks`

Create `android/key.properties`

```sh
storePassword=$password
keyPassword=$password
keyAlias=upload
storeFile=$HOME/upload-keystore.jks
```

#### Publishing

`flutter build appbundle`

We ship debug mode as it makes it easy to debug issues in production.

In the Play Console for dashboards@flutter.dev, upload the new app.aab output.