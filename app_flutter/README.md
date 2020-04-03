# Build Dashboard v2 Frontend

[Design Doc](https://flutter.dev/go/build-dashboard-v2)

## Running for web locally

`flutter run -d chrome --web-port=8080`

Must run on port 8080 for Google Sign In to work since that is the
only enabled port for localhost.

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

Imports in Dart files in this project should be split into five groups
separated by blank lines:

1. `dart:` imports
2. `package:` imports other than cocoon_service and app_flutter
3. `package:cocoon_service` imports
4. `package:app_flutter` imports (only applicable to tests)
5. local imports

Each section should be sorted lexically.
