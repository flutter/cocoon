// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/storage.dart';

class FakeStorage implements Storage {
  @override
  Bucket bucket(String bucketName,
          {PredefinedAcl defaultPredefinedObjectAcl, Acl defaultObjectAcl}) =>
      FakeBucket();

  @override
  Future<bool> bucketExists(String bucketName) => null;

  @override
  Future<BucketInfo> bucketInfo(String bucketName) => null;

  @override
  Future copyObject(String src, String dest) => null;

  @override
  Future createBucket(String bucketName,
          {PredefinedAcl predefinedAcl, Acl acl}) =>
      null;

  @override
  Future deleteBucket(String bucketName) => null;

  @override
  Stream<String> listBucketNames() => null;

  @override
  Future<Page<String>> pageBucketNames({int pageSize = 50}) => null;
}

class FakeBucket implements Bucket {
  @override
  String absoluteObjectName(String objectName) => null;

  @override
  // TODO: implement bucketName
  String get bucketName => null;

  @override
  Future delete(String name) => null;

  @override
  Future<ObjectInfo> info(String name) => null;

  @override
  Stream<BucketEntry> list({String prefix}) => null;

  @override
  Future<Page<BucketEntry>> page({String prefix, int pageSize = 50}) => null;

  @override
  Stream<List<int>> read(String objectName, {int offset, int length}) => null;

  @override
  Future updateMetadata(String objectName, ObjectMetadata metadata) => null;

  @override
  StreamSink<List<int>> write(String objectName,
          {int length,
          ObjectMetadata metadata,
          Acl acl,
          PredefinedAcl predefinedAcl,
          String contentType}) =>
      null;

  @override
  Future<ObjectInfo> writeBytes(String name, List<int> bytes,
          {ObjectMetadata metadata,
          Acl acl,
          PredefinedAcl predefinedAcl,
          String contentType}) =>
      Future<ObjectInfo>.value(FakeObjectInfo());
}

class FakeObjectInfo implements ObjectInfo {
  @override
  // TODO: implement crc32CChecksum
  int get crc32CChecksum => null;

  @override
  // TODO: implement downloadLink
  Uri get downloadLink => null;

  @override
  // TODO: implement etag
  String get etag => null;

  @override
  // TODO: implement generation
  ObjectGeneration get generation => null;

  @override
  // TODO: implement length
  int get length => null;

  @override
  // TODO: implement md5Hash
  List<int> get md5Hash => null;

  @override
  // TODO: implement metadata
  ObjectMetadata get metadata => null;

  @override
  // TODO: implement name
  String get name => null;

  @override
  // TODO: implement updated
  DateTime get updated => null;
}
