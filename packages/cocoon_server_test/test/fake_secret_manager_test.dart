// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/fake_secret_manager.dart';
import 'package:test/test.dart';

void main() {
  late FakeSecretManager secrets;

  setUp(() {
    secrets = FakeSecretManager();
  });

  test('reads bytes', () async {
    secrets.putBytes('Hello', [1, 2, 3]);
    await expectLater(secrets.tryGetBytes('Hello'), completion([1, 2, 3]));
  });

  test('missing bytes', () async {
    await expectLater(secrets.tryGetBytes('Hello'), completion(isNull));

    secrets.putBytes('Hello', [1, 2, 3]);
    secrets.remove('Hello');
    await expectLater(secrets.tryGetBytes('Hello'), completion(isNull));
  });

  test('reads string', () async {
    secrets.putString('Hello', 'World');
    await expectLater(secrets.tryGetString('Hello'), completion('World'));
  });

  test('missing string', () async {
    await expectLater(secrets.tryGetString('Hello'), completion(isNull));

    secrets.putString('Hello', 'World');
    secrets.remove('Hello');
    await expectLater(secrets.tryGetString('Hello'), completion(isNull));
  });
}
