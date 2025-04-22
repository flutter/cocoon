// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/rpc_model.dart' as rpc_model;
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/request_handlers/get_build_status_badge.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/service/fake_firestore_service.dart';

void main() {
  useTestLoggerPerTest();

  final handler = GetBuildStatusBadge(
    config: FakeConfig(),
    buildStatusService: BuildStatusService(firestore: FakeFirestoreService()),
  );

  test('passing status', () async {
    final buildStatusResponse = rpc_model.BuildStatusResponse(
      buildStatus: rpc_model.BuildStatus.success,
      failingTasks: <String>[],
    );
    final response = handler.generateSVG(buildStatusResponse);
    expect(response, contains('Flutter CI: passing'));
    expect(response, contains(GetBuildStatusBadge.green));
  });

  test('failing status', () async {
    final buildStatusResponse = rpc_model.BuildStatusResponse(
      buildStatus: rpc_model.BuildStatus.failure,
      failingTasks: <String>['a', 'b', 'c'],
    );
    final response = handler.generateSVG(buildStatusResponse);
    expect(response, contains('Flutter CI: 3 failures'));
    expect(response, contains(GetBuildStatusBadge.red));
  });
}
