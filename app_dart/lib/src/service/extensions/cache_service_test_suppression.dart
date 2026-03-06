// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';

import '../../model/firestore/suppressed_test.dart';
import '../cache_service.dart';
import '../firestore.dart';

/// Handy extension on the caching service for test suppression.
extension SuppressedTestCache on CacheService {
  static const String _subcacheName = 'test_suppression';

  Future<bool> isTestSuppressed({
    required String testName,
    required RepositorySlug repository,
    required FirestoreService firestore,
  }) async {
    final cacheValue = await getOrCreate(
      _subcacheName,
      '${repository.fullName}/$testName',
      createFn: () async {
        final latest = await SuppressedTest.getLatest(
          firestore,
          repository.fullName,
          testName,
        );
        if (latest == null) return false.toUint8List();
        return latest.isSuppressed.toUint8List();
      },
      // Only cache for a short while.
      ttl: const Duration(minutes: 5),
    );

    return cacheValue?.toBool() ?? false;
  }

  Future<void> setTestSuppression({
    required String testName,
    required RepositorySlug repository,
    required bool isSuppressed,
  }) async {
    await set(
      _subcacheName,
      '${repository.fullName}/$testName',
      isSuppressed.toUint8List(),
      ttl: const Duration(minutes: 5),
    );
  }
}
