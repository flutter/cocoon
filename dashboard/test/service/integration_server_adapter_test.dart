// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/cocoon_integration_test.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:flutter_dashboard/service/data_seeder.dart';
import 'package:flutter_dashboard/service/integration_server_adapter.dart';
import 'package:flutter_dashboard/service/scenarios.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  useTestLoggerPerTest();
  test('IntegrationServerAdapter fetches seeded data', () async {
    final server = IntegrationServer();
    final adapter = IntegrationServerAdapter(server, seed: true);
    final response = await adapter.fetchCommitStatuses(repo: 'flutter');

    expect(response.error, isNull);
    expect(response.data, isNotNull);
    expect(response.data!.length, 25);

    final firstCommitStatus = response.data!.first;
    expect(firstCommitStatus.commit.repository, 'flutter/flutter');
    expect(firstCommitStatus.tasks.length, 100);
  });

  test('IntegrationServerAdapter allGreen scenario', () async {
    final server = IntegrationServer();
    final adapter = IntegrationServerAdapter(server, seed: false);
    DataSeeder(server, scenario: Scenario.allGreen).seed();

    final response = await adapter.fetchCommitStatuses(repo: 'flutter');
    final tasks = response.data!.first.tasks;
    expect(tasks.every((t) => t.status == TaskStatus.succeeded), true);
  });

  test('IntegrationServerAdapter redTree scenario', () async {
    final server = IntegrationServer();
    final adapter = IntegrationServerAdapter(server, seed: false);
    DataSeeder(server, scenario: Scenario.redTree).seed();

    final response = await adapter.fetchCommitStatuses(repo: 'flutter');
    final latestCommitTasks = response.data!.first.tasks;
    // In redTree, the newest commit has all failed tasks
    expect(latestCommitTasks.every((t) => t.status == TaskStatus.failed), true);

    // Older commits should have realistic distribution
    final secondCommitTasks = response.data![1].tasks;
    expect(
      secondCommitTasks.any((t) => t.status == TaskStatus.succeeded),
      true,
    );
  });
}
