// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:codesign/codesign.dart' as cs;

class FakeCodesignContext extends cs.CodesignContext {
  FakeCodesignContext(
      {required super.codesignCertName,
      required super.codesignUserName,
      required super.appSpecificPassword,
      required super.codesignAppstoreId,
      required super.codesignTeamId,
      required super.commitHash,
      super.production = false});
}

void main() {
  const String randomString = 'abcd1234';

  FakeCodesignContext codesignContext = FakeCodesignContext(
      codesignCertName: randomString,
      codesignUserName: randomString,
      appSpecificPassword: randomString,
      codesignAppstoreId: randomString,
      codesignTeamId: randomString,
      commitHash: randomString);

  test('nothing', () async {
    await codesignContext.run();
  });
}
