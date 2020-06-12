// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_datastore.dart';

void main() {
  group('repoNameForBuilder', () {
    FakeDatastoreDB datastore;
    Config config;
    setUp(() {
      datastore = FakeDatastoreDB();
      config = Config(datastore, CacheService(inMemory: true));
    });
    test('Builder config does not exist', () async {
      final RepositorySlug result =
          await config.repoNameForBuilder('DoesNotExist');
      expect(result, isNull);
    });

    test('Builder exists', () async {
      final RepositorySlug result = await config.repoNameForBuilder('Cocoon');
      expect(result, isNotNull);
      expect(result.fullName, equals('flutter/cocoon'));
    });
  });
}
