import 'dart:async';

import 'package:gcloud/storage.dart';

class FakeGcs implements Storage {
  @override
  Bucket bucket(String bucketName, {PredefinedAcl? defaultPredefinedObjectAcl, Acl? defaultObjectAcl}) {
    return FakeBucket(bucketName);
  }

  @override
  Future<bool> bucketExists(String bucketName) {
    throw UnimplementedError();
  }

  @override
  Future<BucketInfo> bucketInfo(String bucketName) {
    throw UnimplementedError();
  }

  @override
  Future copyObject(String src, String dest) {
    throw UnimplementedError();
  }

  @override
  Future createBucket(String bucketName, {PredefinedAcl? predefinedAcl, Acl? acl}) {
    throw UnimplementedError();
  }

  @override
  Future deleteBucket(String bucketName) {
    throw UnimplementedError();
  }

  @override
  Stream<String> listBucketNames() {
    throw UnimplementedError();
  }

  @override
  Future<Page<String>> pageBucketNames({int pageSize = 50}) {
    throw UnimplementedError();
  }
}

class FakeBucket implements Bucket {
  const FakeBucket(this.bucketName);

  @override
  String absoluteObjectName(String objectName) {
    throw UnimplementedError();
  }

  @override
  final String bucketName;

  @override
  Future delete(String name) {
    throw UnimplementedError();
  }

  @override
  Future<ObjectInfo> info(String name) async {
    throw UnimplementedError();
  }

  @override
  Stream<BucketEntry> list({String? prefix, String? delimiter}) {
    // TODO(chillers): Implement list.
    throw UnimplementedError();
  }

  @override
  Future<Page<BucketEntry>> page({String? prefix, String? delimiter, int pageSize = 50}) {
    throw UnimplementedError();
  }

  @override
  Stream<List<int>> read(String objectName, {int? offset, int? length}) {
    throw UnimplementedError();
  }

  @override
  Future updateMetadata(String objectName, ObjectMetadata metadata) {
    throw UnimplementedError();
  }

  @override
  StreamSink<List<int>> write(
    String objectName, {
    int? length,
    ObjectMetadata? metadata,
    Acl? acl,
    PredefinedAcl? predefinedAcl,
    String? contentType,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ObjectInfo> writeBytes(
    String name,
    List<int> bytes, {
    ObjectMetadata? metadata,
    Acl? acl,
    PredefinedAcl? predefinedAcl,
    String? contentType,
  }) {
    throw UnimplementedError();
  }
}

class FakeBucketItem implements BucketEntry {
  const FakeBucketItem({
    required this.name,
    this.isDirectory = true,
  });

  @override
  final bool isDirectory;

  @override
  bool get isObject => throw UnimplementedError();

  @override
  final String name;
}
