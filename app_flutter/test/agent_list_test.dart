// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cocoon_service/protos.dart' show Agent;

import 'package:app_flutter/agent_list.dart';
import 'package:app_flutter/agent_tile.dart';

void main() {
  group('AgentList', () {
    testWidgets('empty list of agents shows loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AgentList(agents: <Agent>[])));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('list of agents shows unhealthy agents first', (WidgetTester tester) async {
      final List<Agent> agents = <Agent>[
        Agent()
          ..agentId = 'healthy1'
          ..healthCheckTimestamp = Int64.parseInt(DateTime.now().millisecondsSinceEpoch.toString())
          ..isHealthy = true
          ..healthDetails = '''
ssh-connectivity: succeeded
    Last known IP address: 192.168.1.29

android-device-ZY223D6B7B: succeeded
has-healthy-devices: succeeded
    Found 1 healthy devices

cocoon-authentication: succeeded
cocoon-connection: succeeded
able-to-perform-health-check: succeeded''',
        Agent()
          ..agentId = 'sick'
          ..healthCheckTimestamp = Int64.parseInt(DateTime.now().millisecondsSinceEpoch.toString())
          ..isHealthy = false,
        Agent()
          ..agentId = 'healthy2'
          ..healthCheckTimestamp = Int64.parseInt(DateTime.now().millisecondsSinceEpoch.toString())
          ..isHealthy = true
          ..healthDetails = '''
ssh-connectivity: succeeded
    Last known IP address: 192.168.1.29

android-device-ZY223D6B7B: succeeded
has-healthy-devices: succeeded
    Found 1 healthy devices

cocoon-authentication: succeeded
cocoon-connection: succeeded
able-to-perform-health-check: succeeded''',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgentList(agents: agents, insertKeys: true),
          ),
        ),
      );

      expect(find.byKey(const Key('0-sick')), findsOneWidget);
      expect(find.byKey(const Key('1-healthy1')), findsOneWidget);
      expect(find.byKey(const Key('2-healthy2')), findsOneWidget);
    });

    testWidgets('filter agents', (WidgetTester tester) async {
      final List<Agent> agents = <Agent>[
        Agent()
          ..agentId = 'secret agent'
          ..healthCheckTimestamp = Int64.parseInt(DateTime.now().millisecondsSinceEpoch.toString())
          ..isHealthy = true,
        Agent()
          ..agentId = 'pigeon'
          ..healthCheckTimestamp = Int64.parseInt(DateTime.now().millisecondsSinceEpoch.toString())
          ..isHealthy = false,
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgentList(agents: agents, agentFilter: 'pigeon', insertKeys: true),
          ),
        ),
      );

      expect(find.byKey(const Key('0-pigeon')), findsOneWidget);
      expect(find.byType(AgentTile), findsOneWidget);
    });
  });
}
