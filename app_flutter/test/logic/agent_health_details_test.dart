// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cocoon_service/models.dart' show Agent;

import 'package:app_flutter/logic/agent_health_details.dart';

final DateTime pingTime = DateTime.utc(2010, 5, 6, 12, 30);
final DateTime soonTime = pingTime.add(
  const Duration(minutes: AgentHealthDetails.minutesUntilAgentIsUnresponsive ~/ 2),
);
final DateTime laterTime = pingTime.add(
  const Duration(minutes: AgentHealthDetails.minutesUntilAgentIsUnresponsive * 2),
);

void main() {
  test('is healthy when everything is healthy', () {
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

    expect(healthDetails.canPerformHealthCheck, isTrue);
    expect(healthDetails.cocoonAuthentication, isTrue);
    expect(healthDetails.cocoonConnection, isTrue);
    expect(healthDetails.hasHealthyDevices, isTrue);
    expect(healthDetails.hasSshConnectivity, isTrue);
    expect(healthDetails.pingedRecently(soonTime), isTrue);
    expect(healthDetails.pingedRecently(laterTime), isFalse);
    expect(healthDetails.isHealthy(soonTime), isTrue);
    expect(healthDetails.isHealthy(laterTime), isFalse);
  });

  test('is not healthy when just one metric is unhealthy', () {
    final Agent agent = Agent()
      ..healthCheckTimestamp = pingTime.millisecondsSinceEpoch
      ..isHealthy = false
      ..healthDetails = '''
ssh-connectivity: succeeded
  Last known IP address: 192.168.1.226

ios-device-b4873f14ffb248dfcb00c8cb7fdd4cdcff87f1f0: succeeded

cocoon-authentication: succeeded
cocoon-connection: succeeded
ios: failed
  ERROR: Command "/Users/flutter/.cocoon/flutter/bin/flutter build ios" failed with exit code 1.
  #0      fail (package:cocoon_agent/src/utils.dart:140:3)
  #1      exec (package:cocoon_agent/src/utils.dart:341:5)
  <asynchronous suspension>
  #2      flutter (package:cocoon_agent/src/utils.dart:369:10)
  #3      performHealthChecks.<anonymous closure>.<anonymous closure>.<anonymous closure> (package:cocoon_agent/src/health.dart:58:34)
  <asynchronous suspension>
  #4      inDirectory (package:cocoon_agent/src/utils.dart:382:24)
  <asynchronous suspension>
  #5      performHealthChecks.<anonymous closure>.<anonymous closure> (package:cocoon_agent/src/health.dart:57:17)
  <asynchronous suspension>
  #6      _captureErrors (package:cocoon_agent/src/health.dart:90:47)
  <asynchronous suspension>
  #7      performHealthChecks.<anonymous closure> (package:cocoon_agent/src/health.dart:47:30)
  <asynchronous suspension>
  #8      _captureErrors (package:cocoon_agent/src/health.dart:90:47)
  <asynchronous suspension>
  #9      performHealthChecks (package:cocoon_agent/src/health.dart:20:51)
  <asynchronous suspension>
  #10     ContinuousIntegrationCommand.run.<anonymous closure> (package:cocoon_agent/src/commands/ci.dart:75:26)
  <asynchronous suspension>
  #11     _rootRun (dart:async/zone.dart:1124:13)
  #12     _CustomZone.run (dart:async/zone.dart:1021:19)
  #13     _runZoned (dart:async/zone.dart:1516:10)
  #14     runZoned (dart:async/zone.dart:1500:12)
  #15     ContinuousIntegrationCommand.run (package:cocoon_agent/src/commands/ci.dart:63:13)
  <asynchronous suspension>
  #16     main (file:///Users/flutter/cocoon/agent/bin/agent.dart:63:19)
  <asynchronous suspension>
  #17     _startIsolate.<anonymous closure> (dart:isolate-patch/isolate_patch.dart:303:32)
  #18     _RawReceivePortImpl._handleMessage (dart:isolate-patch/isolate_patch.dart:172:12)

able-to-perform-health-check: succeeded''';

    final AgentHealthDetails healthDetails = AgentHealthDetails(agent);

    expect(healthDetails.canPerformHealthCheck, isTrue);
    expect(healthDetails.cocoonAuthentication, isTrue);
    expect(healthDetails.cocoonConnection, isTrue);
    expect(healthDetails.hasHealthyDevices, isFalse);
    expect(healthDetails.hasSshConnectivity, isTrue);
    expect(healthDetails.pingedRecently(soonTime), isTrue);
    expect(healthDetails.isHealthy(soonTime), isFalse);
    expect(healthDetails.pingedRecently(laterTime), isFalse);
    expect(healthDetails.isHealthy(laterTime), isFalse);
  });

  test('is not healthy when all metrics are healthy but has timed out', () {
    final Agent agent = Agent()
      ..healthCheckTimestamp = 10000
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

    expect(healthDetails.canPerformHealthCheck, isTrue);
    expect(healthDetails.cocoonAuthentication, isTrue);
    expect(healthDetails.cocoonConnection, isTrue);
    expect(healthDetails.hasHealthyDevices, isTrue);
    expect(healthDetails.hasSshConnectivity, isTrue);
    expect(healthDetails.pingedRecently(soonTime), isFalse);
    expect(healthDetails.isHealthy(soonTime), isFalse);
    expect(healthDetails.pingedRecently(laterTime), isFalse);
    expect(healthDetails.isHealthy(laterTime), isFalse);
  });

  test('is unhealthy when health details is null', () {
    final Agent agent = Agent()
      ..healthCheckTimestamp = 10000
      ..isHealthy = false;

    final AgentHealthDetails healthDetails = AgentHealthDetails(agent);

    expect(healthDetails.canPerformHealthCheck, isFalse);
    expect(healthDetails.cocoonAuthentication, isFalse);
    expect(healthDetails.cocoonConnection, isFalse);
    expect(healthDetails.hasHealthyDevices, isFalse);
    expect(healthDetails.hasSshConnectivity, isFalse);
    expect(healthDetails.pingedRecently(soonTime), isFalse);
    expect(healthDetails.isHealthy(soonTime), isFalse);
    expect(healthDetails.pingedRecently(laterTime), isFalse);
    expect(healthDetails.isHealthy(laterTime), isFalse);
  });
}
