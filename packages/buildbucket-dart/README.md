# Dart Buildbucket

Dart LUCI buildbucket protobufs.

## Details

These protobufs are used to communicate with LUCI Buildbucket services from Dart Language.

## Regenerating the protos

* Run `dart pub global activate protoc_plugin`.
* From `packages/buildbucket-dart` run `bash tool/regenerate.sh`.

That will checkout protobuf, buildbucket and googleapis repositories. It will also compile the protos
and generate their correspondent Dart classes.

## Feedback

File an issue in flutter/flutter with the word 'buildbucket-dart' clearly in the title and cc @godofredoc.
