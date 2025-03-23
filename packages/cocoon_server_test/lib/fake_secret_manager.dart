// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:cocoon_server/secret_manager.dart';

/// A fake (in-memory) implementation of [SecretManager].
final class FakeSecretManager extends SecretManager {
  final _secrets = <String, Uint8List>{};

  /// Adds (or replaces an existing) secret as bytes.
  void putBytes(String name, List<int> value) {
    _secrets[name] = Uint8List.fromList(value);
  }

  /// Adds (or replace an existing) secrets as a UTF-16 string.
  void putString(String name, String value) {
    putBytes(name, value.codeUnits);
  }

  /// Removes a secret.
  void remove(String name) {
    _secrets.remove(name);
  }

  @override
  Future<Uint8List?> tryGetBytes(String name) async {
    return _secrets[name]?.sublist(0);
  }
}
