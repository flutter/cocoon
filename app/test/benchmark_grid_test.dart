// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
@TestOn('dartium')

import 'dart:async';
import 'dart:convert' show json;
import 'dart:html';
import 'dart:math' as math;

import 'package:angular/angular.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:cocoon/components/benchmark_grid.dart';

void main() {
  group('BenchmarkGrid', () {
    setUp(() {
      document.body.append(new Element.tag('benchmark-grid'));
    });

    tearDown(() {
      for (Node node in document.body.querySelectorAll('benchmark-grid')) {
        node.remove();
      }
    });

    test('should show a grid', () async {
      List<String> httpCalls = <String>[];

      var componentRef = await runAppLegacyAsync(
        BenchmarkGrid,
        beforeComponentCreated: (_) async {},
        createInjectorFromProviders: [
        provide(http.Client, useValue: new MockClient((http.Request request) async {
          httpCalls.add(request.url.path);
          return new http.Response(
              json.encode(_testData),
              200,
              headers: {'content-type': 'application/json'});
        })),
      ]);

      // Flush microtasks to allow Angular do its thing.
      await new Future.delayed(Duration.zero);

      expect(httpCalls, <String>['/api/get-benchmarks']);
      expect(document.querySelectorAll('benchmark-card'), hasLength(5));

      BenchmarkGrid component = componentRef.instance;
      expect(component.isShowArchived, isFalse);
      document.body.querySelector('#toggleArchived').click();
      expect(component.isShowArchived, isTrue);

      await new Future.delayed(Duration.zero);

      expect(component.visibleBenchmarks, hasLength(10));
      expect(document.querySelectorAll('benchmark-card'), hasLength(10));

      component.applyTextFilter('series 1');
      expect(component.visibleBenchmarks.single.timeseries.timeseries.label, 'Series 1');
    });
  });

  group('computeSecondHighest', () {
    void expectSecondHighest(List<double> values, double expected) {
      expect(computeSecondHighest(values), expected);
    }

    test('defaults to zero on empty list', () {
      expectSecondHighest(<double>[], 0.0);
    });

    test('pick the only element in the 1-element list', () {
      expectSecondHighest(<double>[3.0], 3.0);
    });

    test('pick the second highest element', () {
      expectSecondHighest(<double>[1.0, 3.0, 2.0], 2.0);
    });
  });
}

final math.Random _rnd = new math.Random(1234);

final _testData = {
  'Benchmarks': new List<Map<String, dynamic>>.generate(10, (int i) => {
    'Timeseries': {
      'Key': 'key$i',
      'Timeseries': {
        'ID': 'series$i',
        'Label': 'Series $i',
        'Unit': 'ms',
        'Goal': (40 + _rnd.nextInt(60)).toDouble(),
        'Baseline': (40 + _rnd.nextInt(60)).toDouble(),
        'Archived': i % 2 != 0,  // make half of them archived
      },
    },
    'Values': new List.generate(_rnd.nextInt(5), (int v) => {
      'CreateTimestamp': 1234567890000 - v,
      'Revision': 'rev$v',
      'Value': (50 + _rnd.nextInt(50)).toDouble(),
    }),
  }),
};
