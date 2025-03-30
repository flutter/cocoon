// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/src/common/model/repos.dart';

final class FakeFusionTester extends FusionTester {
  bool Function(RepositorySlug slug) isFusion = (_) => false;

  @override
  Future<bool> isFusionBasedRef(RepositorySlug slug) async {
    return isFusion.call(slug);
  }
}
