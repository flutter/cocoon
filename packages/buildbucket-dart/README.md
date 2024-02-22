# Dart Buildbucket

Dart LUCI buildbucket protobufs.

## Details

These protobufs are used to communicate with LUCI Buildbucket services from Dart Language.

## Regenerating the protos

* Run `dart pub global activate protoc_plugin`.
* From `packages/buildbucket-dart` run `bash tool/regenerate.sh`.

That will checkout protobuf, buildbucket and googleapis repositories. It will also compile the protos
and generate their correspondent Dart classes.

## Validating Changes

In order to validate the changes you have made before releasing a new version you can point your project
to the local directory for packages/buildbucket-dart by doing the following in your project's pubspec.yaml:

```dart
    dependencies:
      buildbucket-dart:
        path: /your/path/to/packages/buildbucket-dart
```

## Feedback

File an issue in flutter/flutter with the word 'buildbucket-dart' clearly in the title and cc @godofredoc.
