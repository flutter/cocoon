// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/service/access_client_provider.dart';
import 'package:cocoon_service/src/service/firestore.dart';

import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

void main() {
  test('creates writes correctly from documents', () async {
    final List<Document> documents = <Document>[
      Document(name: 'd1', fields: <String, Value>{'key1': Value(stringValue: 'value1')}),
      Document(name: 'd2', fields: <String, Value>{'key1': Value(stringValue: 'value2')}),
    ];
    final List<Write> writes = documentsToWrites(documents, exists: false);
    expect(writes.length, documents.length);
    expect(writes[0].update, documents[0]);
    expect(writes[0].currentDocument!.exists, false);
  });

  group('getValueFromFilter', () {
    final FirestoreService firestoreService = FirestoreService(AccessClientProvider());
    test('int object', () async {
      const Object intValue = 1;
      expect(firestoreService.getValueFromFilter(intValue).integerValue, '1');
    });

    test('string object', () async {
      const Object stringValue = 'string';
      expect(firestoreService.getValueFromFilter(stringValue).stringValue, 'string');
    });

    test('bool object', () async {
      const Object boolValue = true;
      expect(firestoreService.getValueFromFilter(boolValue).booleanValue, true);
    });
  });

  group('generateFilter', () {
    final FirestoreService firestoreService = FirestoreService(AccessClientProvider());
    test('a field filter', () async {
      final Map<String, Object> filterMap = <String, Object>{
        'intField =': 1,
      };
      const String compositeFilterOp = kCompositeFilterOpAnd;
      final Filter filter = firestoreService.generateFilter(filterMap, compositeFilterOp);
      expect(filter.fieldFilter, isNotNull);
      expect(filter.compositeFilter, isNull);
      expect(filter.fieldFilter!.field!.fieldPath, 'intField');
      expect(filter.fieldFilter!.value!.integerValue, '1');
      expect(filter.fieldFilter!.op, kFieldFilterOpEqual);
    });

    test('a composite filter', () async {
      final Map<String, Object> filterMap = <String, Object>{
        'intField =': 1,
        'stringField =': 'string',
      };
      const String compositeFilterOp = kCompositeFilterOpAnd;
      final Filter filter = firestoreService.generateFilter(filterMap, compositeFilterOp);
      expect(filter.fieldFilter, isNull);
      expect(filter.compositeFilter, isNotNull);
      final List<Filter> filters = filter.compositeFilter!.filters!;
      expect(filters.length, 2);
      expect(filters[0].fieldFilter!.field!.fieldPath, 'intField');
      expect(filters[0].fieldFilter!.value!.integerValue, '1');
      expect(filters[0].fieldFilter!.op, kFieldFilterOpEqual);
      expect(filters[1].fieldFilter!.field!.fieldPath, 'stringField');
      expect(filters[1].fieldFilter!.value!.stringValue, 'string');
      expect(filters[1].fieldFilter!.op, kFieldFilterOpEqual);
    });
  });
}
