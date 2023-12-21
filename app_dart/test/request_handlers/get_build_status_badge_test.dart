// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/protos.dart';
import 'package:cocoon_service/src/request_handlers/get_build_status_badge.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';

void main() {
  final GetBuildStatusBadge handler = GetBuildStatusBadge(config: FakeConfig());

  test('passing status', () async {
    final BuildStatusResponse buildStatusResponse = BuildStatusResponse()..buildStatus = EnumBuildStatus.success;
    final String response = handler.generateSVG(buildStatusResponse);
    expect(response, contains('Flutter CI: passing'));
    expect(response, contains(GetBuildStatusBadge.green));
  });

  test('failing status', () async {
    final BuildStatusResponse buildStatusResponse = BuildStatusResponse()
      ..buildStatus = EnumBuildStatus.failure
      ..failingTasks.addAll(<String>['a', 'b', 'c']); // 3 failing tasks
    final String response = handler.generateSVG(buildStatusResponse);
    expect(response, contains('Flutter CI: 3 failures'));
    expect(response, contains(GetBuildStatusBadge.red));
  });
}
