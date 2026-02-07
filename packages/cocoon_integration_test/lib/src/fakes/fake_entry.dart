// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:neat_cache/neat_cache.dart';

class FakeEntry extends Entry<Uint8List> {
  Uint8List value = Uint8List.fromList('abc123'.codeUnits);

  @override
  Future<Uint8List> get([
    Future<Uint8List?> Function()? create,
    Duration? ttl,
  ]) async => value;

  @override
  Future<void> purge({int retries = 0}) => throw UnimplementedError();

  @override
  Future<Uint8List?> set(Uint8List? value, [Duration? ttl]) async {
    value = value;

    return value;
  }
}
