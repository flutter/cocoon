// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

import 'package:cocoon_service/protos.dart' show Agent;

import 'package:app_flutter/service/cocoon.dart';
import 'package:app_flutter/service/dev_cocoon.dart';

void main() {
  testWidgets('DevelopmentCocoonService agents don\'t duplicate', (WidgetTester tester) async {
    final DevelopmentCocoonService cocoon = DevelopmentCocoonService(DateTime(0));
    CocoonResponse<List<Agent>> agents;
    await tester.runAsync<void>(() async {
      agents = await cocoon.fetchAgentStatuses();
    });
    final Set<Agent> agentSet = Set<Agent>.from(agents.data);
    expect(agentSet.length, agents.data.length);
  });
}
