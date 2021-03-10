// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cocoon_service/models.dart' show Agent;

import 'package:app_flutter/logic/agent_health_details.dart';
import 'package:app_flutter/widgets/agent_health_details_bar.dart';
import 'package:app_flutter/widgets/now.dart';

final DateTime pingTime = DateTime.utc(2010, 5, 6, 12, 30);
final DateTime soonTime = pingTime.add(
  const Duration(minutes: AgentHealthDetails.minutesUntilAgentIsUnresponsive ~/ 2),
);
final DateTime laterTime = pingTime.add(
  const Duration(minutes: AgentHealthDetails.minutesUntilAgentIsUnresponsive * 2),
);

void main() {
  testWidgets('healthy bar', (WidgetTester tester) async {
    final Agent agent = Agent()
      ..healthCheckTimestamp = pingTime.millisecondsSinceEpoch
      ..isHealthy = true
      ..healthDetails = '''
ssh-connectivity: succeeded
  Last known IP address: 192.168.1.29

android-device-ZY223D6B7B: succeeded
has-healthy-devices: succeeded
  Found 1 healthy devices

cocoon-authentication: succeeded
cocoon-connection: succeeded
able-to-perform-health-check: succeeded''';

    final AgentHealthDetails healthDetails = AgentHealthDetails(agent);

    await tester.pumpWidget(
      Now.fixed(
        dateTime: soonTime,
        child: MaterialApp(
          home: AgentHealthDetailsBar(healthDetails),
        ),
      ),
    );

    expect(find.byIcon(Icons.timer), findsNothing);
    expect(find.byIcon(Icons.verified_user), findsOneWidget);
    expect(find.byIcon(Icons.network_wifi), findsOneWidget);
    expect(find.byIcon(Icons.devices), findsOneWidget);
  });

  testWidgets('timed out icon', (WidgetTester tester) async {
    final Agent agent = Agent()
      ..healthCheckTimestamp = 100
      ..isHealthy = true
      ..healthDetails = '''
ssh-connectivity: succeeded
  Last known IP address: 192.168.1.29

android-device-ZY223D6B7B: succeeded
has-healthy-devices: succeeded
  Found 1 healthy devices

cocoon-authentication: succeeded
cocoon-connection: succeeded
able-to-perform-health-check: succeeded''';

    final AgentHealthDetails healthDetails = AgentHealthDetails(agent);

    await tester.pumpWidget(
      Now.fixed(
        dateTime: soonTime,
        child: MaterialApp(
          home: AgentHealthDetailsBar(healthDetails),
        ),
      ),
    );

    expect(find.byIcon(Icons.timer), findsOneWidget);
    expect(find.byIcon(Icons.verified_user), findsOneWidget);
    expect(find.byIcon(Icons.network_wifi), findsOneWidget);
    expect(find.byIcon(Icons.devices), findsOneWidget);
  });

  testWidgets('unhealthy bar', (WidgetTester tester) async {
    final Agent agent = Agent()
      ..healthCheckTimestamp = 100
      ..isHealthy = false
      ..healthDetails = '';

    final AgentHealthDetails healthDetails = AgentHealthDetails(agent);

    await tester.pumpWidget(
      Now.fixed(
        dateTime: soonTime,
        child: MaterialApp(
          home: AgentHealthDetailsBar(healthDetails),
        ),
      ),
    );

    expect(find.byIcon(Icons.timer), findsOneWidget);
    expect(find.byIcon(Icons.verified_user), findsNothing);
    expect(find.byIcon(Icons.network_wifi), findsNothing);
    expect(find.byIcon(Icons.devices), findsNothing);
  });
}
