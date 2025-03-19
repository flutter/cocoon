// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/request_handling/authentication.dart';
import 'package:auto_submit/requests/exceptions.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('CronAuthProvider', () {
    late Request request;
    late CronAuthProvider auth;

    setUp(() {
      auth = const CronAuthProvider();
    });

    test('throws Unauthenticated with no auth headers', () async {
      request = Request('POST', Uri.parse('http://localhost/'));
      expect(auth.authenticate(request), throwsA(isA<Unauthenticated>()));
    });

    test('succeeds for App Engine cronjobs', () async {
      final header = <String, String>{'X-Appengine-Cron': 'true'};
      request = Request(
        'POST',
        Uri.parse('http://localhost/'),
        headers: header,
      );
      final result = await auth.authenticate(request);
      expect(result, true);
    });
  });
}
