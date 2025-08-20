// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_common/rpc_model.dart' show ContentHashLookup;
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/content_aware_hash_builds.dart';
import 'package:cocoon_service/src/request_handlers/lookup_hash.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_dashboard_authentication.dart';
import '../src/service/fake_content_aware_hash_service.dart';

void main() {
  useTestLoggerPerTest();

  late ApiRequestHandlerTester tester;
  late FakeConfig config;
  late FakeContentAwareHashService contentAwareHashService;
  late FakeDashboardAuthentication auth;
  late LookupHash lookup;

  setUp(() {
    auth = FakeDashboardAuthentication();
    config = FakeConfig();
    contentAwareHashService = FakeContentAwareHashService(config: config);

    tester = ApiRequestHandlerTester();

    lookup = LookupHash(
      contentAwareHashService: contentAwareHashService,
      config: config,
      authenticationProvider: auth,
    );
  });

  test('searches by param hash', () async {
    contentAwareHashService.buildsByHash['1' * 40] = ContentAwareHashBuilds(
      createdOn: DateTime(2025, 8, 20, 12, 30),
      contentHash: '1' * 40,
      commitSha: 'a' * 40,
      buildStatus: BuildStatus.success,
      waitingShas: ['b' * 40],
    );
    tester.request.uri = tester.request.uri.replace(
      queryParameters: {'hash': '1' * 40},
    );

    final hashes = await tester.get(lookup);

    expect(
      [
        for (var object
            in json.decode(await utf8.decodeStream(hashes.body))
                as List<Object?>)
          ContentHashLookup.fromJson(object as Map<String, Object?>),
      ],
      contains(
        ContentHashLookup(contentHash: '1' * 40, gitShas: ['a' * 40, 'b' * 40]),
      ),
    );
  });
}
