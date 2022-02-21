// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import '../bin/server.dart';

void main() {
  Request req = Request('POST', Uri.parse('http://localhost/'), headers: {
    'header1': 'header value1',
  });
  test('call webhookHandler to handle the request', () async {
    Response response = await webhookHandler(req);
    expect(response.headers, {
      'header1': 'header value1',
      'content-length': '2',
    });
  });
}
