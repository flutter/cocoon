// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:releases/common/handler.dart';
import 'package:releases/common/router.dart';
import 'package:releases/requests/readiness_check.dart';
import 'package:test/test.dart';

void main() {
  <String, int>{
    '/not_found': 404,
    '/readiness_check': 200,
    '/unimplemented': 501,
  }.forEach(
    (url, expectedHttpCode) => test('$url returns HTTP $expectedHttpCode', () async {
      final Router router = Router(<Handler>[const ReadinessCheck(), const UnimplementedHandler()]);
      final Request request = Request('GET', Uri.https('localhost', url));
      final Response response = await router.processRequest(request);
      expect(response.statusCode, expectedHttpCode);
    }),
  );
}

class UnimplementedHandler extends Handler {
  const UnimplementedHandler() : super('unimplemented');
}
