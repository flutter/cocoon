// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/access_client_provider.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

import '../src/utilities/entity_generators.dart';

void main() {
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

  group('getValueFromFilter', () {
    final firestoreService = FirestoreService(AccessClientProvider());
    test('int object', () async {
      const Object intValue = 1;
      expect(firestoreService.getValueFromFilter(intValue).integerValue, '1');
    });

    test('string object', () async {
      const Object stringValue = 'string';
      expect(
        firestoreService.getValueFromFilter(stringValue).stringValue,
        'string',
      );
    });

    test('bool object', () async {
      const Object boolValue = true;
      expect(firestoreService.getValueFromFilter(boolValue).booleanValue, true);
    });
  });

  group('generateFilter', () {
    final firestoreService = FirestoreService(AccessClientProvider());
    test('a composite filter with a single field filter', () async {
      final filterMap = <String, Object>{'intField =': 1};
      const compositeFilterOp = kCompositeFilterOpAnd;
      final filter = firestoreService.generateFilter(
        filterMap,
        compositeFilterOp,
      );
      expect(filter.compositeFilter, isNotNull);
      final filters = filter.compositeFilter!.filters!;
      expect(filters.length, 1);
      expect(
        filters[0].fieldFilter!.field!.fieldPath,
        '`intField`',
        reason: 'field escaped properly',
      );
      expect(filters[0].fieldFilter!.value!.integerValue, '1');
      expect(filters[0].fieldFilter!.op, kFieldFilterOpEqual);
    });

    test('accepts complex field names', () async {
      final filterMap = <String, Object>{
        'this is my field      !=': 'there are many like it ',
      };
      const compositeFilterOp = kCompositeFilterOpAnd;
      final filter = firestoreService.generateFilter(
        filterMap,
        compositeFilterOp,
      );
      expect(filter.compositeFilter, isNotNull);
      final filters = filter.compositeFilter!.filters!;
      expect(filters.length, 1);
      expect(
        filters[0].fieldFilter!.field!.fieldPath,
        '`this is my field`',
        reason: 'field escaped properly',
      );
      expect(
        filters[0].fieldFilter!.value!.stringValue,
        'there are many like it ',
      );
      expect(filters[0].fieldFilter!.op, kFieldFilterOpNotEqual);
    });

    test('a composite filter with multiple field filters', () async {
      final filterMap = <String, Object>{
        'intField =': 1,
        'stringField =': 'string',
      };
      const compositeFilterOp = kCompositeFilterOpAnd;
      final filter = firestoreService.generateFilter(
        filterMap,
        compositeFilterOp,
      );
      expect(filter.fieldFilter, isNull);
      expect(filter.compositeFilter, isNotNull);
      final filters = filter.compositeFilter!.filters!;
      expect(filters.length, 2);
      expect(
        filters[0].fieldFilter!.field!.fieldPath,
        '`intField`',
        reason: 'field escaped properly',
      );
      expect(filters[0].fieldFilter!.value!.integerValue, '1');
      expect(filters[0].fieldFilter!.op, kFieldFilterOpEqual);
      expect(filters[1].fieldFilter!.field!.fieldPath, '`stringField`');
      expect(filters[1].fieldFilter!.value!.stringValue, 'string');
      expect(filters[1].fieldFilter!.op, kFieldFilterOpEqual);
    });
  });

  group('documentsFromQueryResponse', () {
    final firestoreService = FirestoreService(AccessClientProvider());
    late List<RunQueryResponseElement> runQueryResponseElements;
    test('when null document returns', () async {
      runQueryResponseElements = <RunQueryResponseElement>[
        RunQueryResponseElement(),
      ];
      final documents = firestoreService.documentsFromQueryResponse(
        runQueryResponseElements,
      );
      expect(documents.isEmpty, true);
    });

    test('when non-null document returns', () async {
      final githubGoldStatus = generateFirestoreGithubGoldStatus(1);
      runQueryResponseElements = <RunQueryResponseElement>[
        RunQueryResponseElement(document: githubGoldStatus),
      ];
      final documents = firestoreService.documentsFromQueryResponse(
        runQueryResponseElements,
      );
      expect(documents.length, 1);
      expect(documents[0].name, githubGoldStatus.name);
    });
  });

  group('generateOrders', () {
    final firestoreService = FirestoreService(AccessClientProvider());
    Map<String, String>? orderMap;
    test('when there is no orderMap', () async {
      orderMap = null;
      final orders = firestoreService.generateOrders(orderMap);
      expect(orders, isNull);
    });

    test('when there is non-null orderMap', () async {
      orderMap = <String, String>{'createTimestamp': kQueryOrderDescending};
      final orders = firestoreService.generateOrders(orderMap);
      expect(orders!.length, 1);
      final resultOrder = orders[0];
      expect(resultOrder.direction, kQueryOrderDescending);
      expect(resultOrder.field!.fieldPath, 'createTimestamp');
    });
  });
}
