// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:gcloud/storage.dart';
import 'package:meta/meta.dart';

typedef StorageServiceProvider = StorageService Function();

/// Service class for interacting with AppEngine Storage.
///
/// This service exists to provide an API for common storage operations.
@immutable
class StorageService {
  /// Creates a new [StorageService].
  ///
  /// The [storage] argument must not be null.
  const StorageService({
    @required this.storage,
  }) : assert(storage != null);

  /// The backing [Storage] object. Guaranteed to be non-null.
  final Storage storage;

  static StorageService defaultProvider() {
    return StorageService(storage: storageService);
  }

  Future<ObjectInfo> writeTaskLog(String logName, Uint8List bytes) async {
    final Bucket devicelabLogBucket = storage.bucket('flutter-task-logs');
    return devicelabLogBucket.writeBytes(logName, bytes);
  }
}
