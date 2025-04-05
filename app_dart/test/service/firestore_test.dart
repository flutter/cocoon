// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  test('creates writes correctly from documents', () async {
    final documents = <Document>[
      Document(
        name: 'd1',
        fields: <String, Value>{'key1': Value(stringValue: 'value1')},
      ),
      Document(
        name: 'd2',
        fields: <String, Value>{'key1': Value(stringValue: 'value2')},
      ),
    ];
    final writes = documentsToWrites(documents, exists: false);
    expect(writes.length, documents.length);
    expect(writes[0].update, documents[0]);
    expect(writes[0].currentDocument!.exists, false);
  });
}
