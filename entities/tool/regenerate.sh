#!/usr/bin/env bash

if [ ! -d "$PROTOBUF" ]; then
  echo "Please set the PROTOBUF environment variable to your clone of google/protobuf."
  exit -1
fi

if [ ! -d "$GOOGLEAPIS" ]; then
  echo "Please set the GOOGLEAPIS environment variable to your clone of googleapis/googleapis."
  exit -1
fi

PROTOC="protoc --dart_out=grpc:lib/ -I$PROTOBUF/src -I$GOOGLEAPIS"

$PROTOC $GOOGLEAPIS/google/datastore/v1/datastore.proto
$PROTOC $GOOGLEAPIS/google/datastore/v1/query.proto
$PROTOC $GOOGLEAPIS/google/datastore/v1/entity.proto

$PROTOC $GOOGLEAPIS/google/api/monitored_resource.proto
$PROTOC $GOOGLEAPIS/google/api/label.proto
$PROTOC $GOOGLEAPIS/google/api/annotations.proto
$PROTOC $GOOGLEAPIS/google/api/http.proto
$PROTOC $GOOGLEAPIS/google/type/latlng.proto

$PROTOC $GOOGLEAPIS/google/rpc/status.proto

$PROTOC $PROTOBUF/src/google/protobuf/any.proto
$PROTOC $PROTOBUF/src/google/protobuf/duration.proto
$PROTOC $PROTOBUF/src/google/protobuf/empty.proto
$PROTOC $PROTOBUF/src/google/protobuf/struct.proto
$PROTOC $PROTOBUF/src/google/protobuf/timestamp.proto
$PROTOC $PROTOBUF/src/google/protobuf/wrappers.proto
$PROTOC $PROTOBUF/src/google/protobuf/descriptor.proto

dartfmt -w lib/