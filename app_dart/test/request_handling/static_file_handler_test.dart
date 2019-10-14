// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/request_handling/exceptions.dart';

void main() {
  group('StaticFileHandler', () {
    test('returns 404 response when file does not exist', () async {
      const StaticFileHandler staticFileHandler = StaticFileHandler();

      final HttpRequest request = MockHttpRequest();
      final Uri uri = Uri();
      when(request.uri).thenReturn(uri);

      expect(staticFileHandler.get(request),
          throwsA(const TypeMatcher<NotFoundException>()));
    });
  });
}

class MockHttpRequest extends Mock implements HttpRequest {}
