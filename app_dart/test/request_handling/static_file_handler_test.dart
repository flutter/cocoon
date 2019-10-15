// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/request_handler_tester.dart';

void main() {
  group('StaticFileHandler', () {
    RequestHandlerTester tester;
    StaticFileHandler<Body> staticFileHandler;

    final FakeConfig config = FakeConfig();

    setUp(() {
      tester = RequestHandlerTester();
    });

    test('returns 404 response when file does not exist', () async {
      staticFileHandler = StaticFileHandler<Body>('null', config: config);

      expect(tester.get(staticFileHandler),
          throwsA(const TypeMatcher<NotFoundException>()));
    });
  });
}

class MockHttpRequest extends Mock implements HttpRequest {}
