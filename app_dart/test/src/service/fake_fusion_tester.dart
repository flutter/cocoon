// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/src/common/model/repos.dart';
import 'package:retry/retry.dart';

class FakeFusionTester implements FusionTester {
  bool Function(
    RepositorySlug slug,
    String ref,
  ) isFusion = (_, __) => false;


  @override
  Future<bool> isFusionBasedRef(
    RepositorySlug slug,
    String ref, {
    Duration timeout = const Duration(seconds: 4),
    RetryOptions retryOptions = const RetryOptions(
      maxAttempts: 3,
      delayFactor: Duration(seconds: 3),
    ),
  }) {
    return Future.value(isFusion(slug, ref));
  }
}
