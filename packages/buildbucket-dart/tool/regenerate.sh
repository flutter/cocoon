#!/usr/bin/env bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -ex

mkdir -p lib/src/generated

rm -rf buildbucket_tmp
mkdir -p buildbucket_tmp
pushd buildbucket_tmp
git clone https://chromium.googlesource.com/infra/luci/luci-go
git clone https://github.com/googleapis/googleapis
git clone https://github.com/protocolbuffers/protobuf
PROTOC="protoc --plugin=protoc-gen-dart=$HOME/.pub-cache/bin/protoc-gen-dart --dart_out=grpc:lib/src/generated -Ibuildbucket_tmp/protobuf/src -Ibuildbucket_tmp/googleapis -Ibuildbucket_tmp/luci-go -Ibuildbucket_tmp/buildbucket"
pushd luci-go
find . -name *.proto -exec bash -c 'path={}; d=../buildbucket/go.chromium.org/luci/$(dirname $path); mkdir -p $d ; cp $path $d' \;
popd
popd
$PROTOC go.chromium.org/luci/buildbucket/proto/build.proto
$PROTOC go.chromium.org/luci/buildbucket/proto/builder_service.proto
$PROTOC go.chromium.org/luci/buildbucket/proto/builds_service.proto
$PROTOC go.chromium.org/luci/buildbucket/proto/builder_common.proto
$PROTOC go.chromium.org/luci/buildbucket/proto/common.proto
$PROTOC go.chromium.org/luci/buildbucket/proto/project_config.proto
$PROTOC go.chromium.org/luci/buildbucket/proto/step.proto
$PROTOC go.chromium.org/luci/buildbucket/proto/task.proto
$PROTOC go.chromium.org/luci/buildbucket/proto/notification.proto
$PROTOC go.chromium.org/luci/resultdb/proto/v1/common.proto
$PROTOC go.chromium.org/luci/resultdb/proto/v1/invocation.proto
$PROTOC go.chromium.org/luci/resultdb/proto/v1/predicate.proto

$PROTOC google/protobuf/any.proto
$PROTOC google/protobuf/duration.proto
$PROTOC google/protobuf/struct.proto
$PROTOC google/protobuf/timestamp.proto
$PROTOC google/protobuf/wrappers.proto
$PROTOC google/protobuf/field_mask.proto
$PROTOC google/rpc/status.proto

