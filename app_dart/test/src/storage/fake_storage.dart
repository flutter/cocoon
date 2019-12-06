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
  Future<void> copyObject(String src, String dest) => null;

  @override
  Future<void> createBucket(String bucketName,
          {PredefinedAcl predefinedAcl, Acl acl}) =>
      null;

  @override
  Future<void> deleteBucket(String bucketName) => null;

  @override
  Stream<String> listBucketNames() => null;

  @override
  Future<Page<String>> pageBucketNames({int pageSize = 50}) => null;
}

class FakeBucket implements Bucket {
  @override
  String absoluteObjectName(String objectName) => null;

  @override
  String get bucketName => null;

  @override
  Future<void> delete(String name) => null;

  @override
  Future<ObjectInfo> info(String name) => null;

  @override
  Stream<BucketEntry> list({String prefix}) => null;

  @override
  Future<Page<BucketEntry>> page({String prefix, int pageSize = 50}) => null;

  @override
  Stream<List<int>> read(String objectName, {int offset, int length}) => null;

  @override
  Future<void> updateMetadata(String objectName, ObjectMetadata metadata) => null;

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
  int get crc32CChecksum => null;

  @override
  Uri get downloadLink => null;

  @override
  String get etag => null;

  @override
  ObjectGeneration get generation => null;

  @override
  int get length => null;

  @override
  List<int> get md5Hash => null;

  @override
  ObjectMetadata get metadata => null;

  @override
  String get name => null;

  @override
  DateTime get updated => null;
}
