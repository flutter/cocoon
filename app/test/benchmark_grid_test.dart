// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
@TestOn('dartium')

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:html';
import 'dart:math' as math;

import 'package:angular2/angular2.dart';
import 'package:angular2/platform/browser.dart';
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

      var component = await bootstrap(BenchmarkGrid, [
        provide(http.Client, useValue: new MockClient((http.Request request) async {
          httpCalls.add(request.url.path);
          return new http.Response(
              JSON.encode(_testData),
              200,
              headers: {'content-type': 'application/json'});
        })),
      ]);

      // Flush microtasks to allow Angular do its thing.
      await new Future.delayed(Duration.ZERO);

      expect(httpCalls, <String>['/api/get-benchmarks']);
      expect(document.querySelectorAll('benchmark-card'), hasLength(5));

      expect(component.instance.isShowArchived, isFalse);
      document.body.querySelector('#toggleArchived').click();
      expect(component.instance.isShowArchived, isTrue);

      await new Future.delayed(Duration.ZERO);

      expect(component.instance.benchmarks, hasLength(10));
      expect(document.querySelectorAll('benchmark-card'), hasLength(10));
    });
  });
}

final math.Random _rnd = new math.Random(1234);

final _testData = {
  'Benchmarks': new List.generate(10, (int i) => {
    'Timeseries': {
      'Key': 'key$i',
      'Timeseries': {
        'ID': 'series$i',
        'Label': 'Series $i',
        'Unit': 'ms',
        'Goal': i.toDouble(),
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
