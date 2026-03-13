// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_integration_test/cocoon_integration_test.dart';
import 'package:flutter_dashboard/service/data_seeder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DataSeeder seeds tree status changes', () async {
    final server = IntegrationServer();
    final seeder = DataSeeder(server);
    seeder.seed();

    final firestore = server.firestore;
    expect(
      firestore.documents.where((d) => d.name!.contains('tree_status_change')),
      isNotEmpty,
    );
  });

  test('DataSeeder seeds suppressed tests', () async {
    final server = IntegrationServer();
    final seeder = DataSeeder(server);
    seeder.seed();

    final firestore = server.firestore;
    expect(
      firestore.documents.where((d) => d.name!.contains('suppressed_tests')),
      isNotEmpty,
    );
  });

  test('DataSeeder seeds presubmit data', () async {
    final server = IntegrationServer();
    final seeder = DataSeeder(server);
    seeder.seed();

    final firestore = server.firestore;
    expect(
      firestore.documents.where((d) => d.name!.contains('presubmit_guards')),
      isNotEmpty,
    );

    expect(
      firestore.documents.where((d) => d.name!.contains('presubmit_checks')),
      isNotEmpty,
    );

    expect(
      firestore.documents.where((d) => d.name!.contains('prCheckRuns')),
      isNotEmpty,
    );
  });
}
