// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/service/config.dart';
import 'package:neat_cache/neat_cache.dart';

class FakeConfig extends Config {
  FakeConfig() : super(cacheProvider: Cache.inMemoryCacheProvider(4));
}
