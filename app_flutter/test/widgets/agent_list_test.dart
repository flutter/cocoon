// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cocoon_service/protos.dart' show Agent;

import 'package:app_flutter/logic/agent_health_details.dart';
import 'package:app_flutter/widgets/agent_list.dart';
import 'package:app_flutter/widgets/agent_tile.dart';
import 'package:app_flutter/widgets/now.dart';

final DateTime pingTime1 = DateTime.utc(2010, 5, 6, 12, 30);
final DateTime pingTime2 = pingTime1.add(const Duration(minutes: 1));
final DateTime pingTime3 = pingTime1.add(const Duration(minutes: 2));
final DateTime soonTime = pingTime1.add(
  const Duration(minutes: AgentHealthDetails.minutesUntilAgentIsUnresponsive ~/ 2),
);
final DateTime laterTime = pingTime1.add(
  const Duration(minutes: AgentHealthDetails.minutesUntilAgentIsUnresponsive * 2),
);

void main() {
  group('AgentList', () {
    testWidgets('empty list of agents shows loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        Now.fixed(
          dateTime: soonTime,
          child: const MaterialApp(
            home: AgentList(agents: <Agent>[]),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('list of agents shows unhealthy agents first', (WidgetTester tester) async {
      final List<Agent> agents = <Agent>[
        Agent()
          ..agentId = 'healthy1'
          ..healthCheckTimestamp = Int64(pingTime1.millisecondsSinceEpoch)
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
          ..healthCheckTimestamp = Int64(pingTime2.millisecondsSinceEpoch)
          ..isHealthy = false,
        Agent()
          ..agentId = 'healthy2'
          ..healthCheckTimestamp = Int64(pingTime3.millisecondsSinceEpoch)
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
        Now.fixed(
          dateTime: soonTime,
          child: MaterialApp(
            home: Scaffold(
              body: AgentList(agents: agents, insertKeys: true),
            ),
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
          ..healthCheckTimestamp = Int64(pingTime1.millisecondsSinceEpoch)
          ..isHealthy = true,
        Agent()
          ..agentId = 'pigeon'
          ..healthCheckTimestamp = Int64(pingTime2.millisecondsSinceEpoch)
          ..isHealthy = false,
      ];

      await tester.pumpWidget(
        Now.fixed(
          dateTime: soonTime,
          child: MaterialApp(
            home: Scaffold(
              body: AgentList(agents: agents, agentFilter: 'pigeon', insertKeys: true),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('0-pigeon')), findsOneWidget);
      expect(find.byType(AgentTile), findsOneWidget);
    });
  });
}
