// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/request_handlers/create_branch.dart';
import 'package:cocoon_service/src/request_handling/request_handler.dart';
import 'package:cocoon_service/src/service/branch_service.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/fake_dashboard_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  group(CreateBranch, () {
    test('runs', () async {
      final tester = RequestHandlerTester();
      tester.request = FakeHttpRequest(
        queryParametersValue: <String, String>{
          CreateBranch.branchParam: 'flutter-3.7-candidate.1',
          CreateBranch.engineShaParam: 'abc123',
        },
      );
      final BranchService branchService = MockBranchService();
      final RequestHandler handler = CreateBranch(
        branchService: branchService,
        config: FakeConfig(),
        authenticationProvider: FakeDashboardAuthentication(),
      );
      await tester.get(handler);
      verify(
        branchService.branchFlutterRecipes('flutter-3.7-candidate.1', 'abc123'),
      ).called(1);
    });
  });
}
