// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:stack_trace/stack_trace.dart';

import 'adb.dart';
import 'agent.dart';
import 'firebase.dart';
import 'utils.dart';

Future<AgentHealth> performHealthChecks(Agent agent) async {
  AgentHealth results = new AgentHealth();

  results['able-to-perform-health-check'] = await _captureErrors(() async {
    results['ssh-connectivity'] = await _captureErrors(_scrapeRemoteAccessInfo);

    if (config.firebaseFlutterDashboardToken != 'test')
      results['firebase-connection'] = await _captureErrors(checkFirebaseConnection);

    Map<String, HealthCheckResult> deviceChecks = await devices.checkDevices();
    results.addAll(deviceChecks);

    bool hasHealthyDevices = deviceChecks.values
        .where((HealthCheckResult r) => r.succeeded)
        .isNotEmpty;

    results['has-healthy-devices'] = hasHealthyDevices
        ? new HealthCheckResult.success('Found ${deviceChecks.length} healthy devices')
        : new HealthCheckResult.failure('No attached devices were found.');

    results['cocoon-connection'] = await _captureErrors(() async {
      String authStatus = await agent.getAuthenticationStatus();

      if (authStatus != 'OK') {
        results['cocoon-authentication'] = new HealthCheckResult.failure('Failed to authenticate to Cocoon. Check config.yaml.');
      } else {
        results['cocoon-authentication'] = new HealthCheckResult.success();
      }
    });
  });

  return results;
}

/// Catches all exceptions and turns them into [HealthCheckResult] error.
///
/// Null callback results are turned into [HealthCheckResult] success.
Future<HealthCheckResult> _captureErrors(Future<dynamic> healthCheckCallback()) async {
  Completer<HealthCheckResult> completer = new Completer<HealthCheckResult>();

  // We intentionally ignore the future returned by the Chain because we're
  // reporting the results via the completer. Instead of reporting a Future
  // error, we report a successful Future carrying a HealthCheckResult error.
  // One way to think about this is that "we _successfully_ discovered health
  // check error, and will report it to the Cocoon back-end".
  // ignore: unawaited_futures
  Chain.capture(() async {
    dynamic result = await healthCheckCallback();
    completer.complete(result is HealthCheckResult ? result : new HealthCheckResult.success());
  }, onError: (error, Chain chain) {
    completer.complete(new HealthCheckResult.error(error, chain.terse));
  });
  return completer.future;
}

/// Returns the IP address for remote (SSH) access to this agent.
///
/// Uses `ipconfig getifaddr en0`.
///
/// Always returns [HealthCheckResult] success regardless of whether an IP
/// is available or not. Having remote access to an agent is not a prerequisite
/// for being able to perform Cocoon tasks. It's only there to make maintenance
/// convenient. The goal is only to report available IPs as part of the health
/// check.
Future<HealthCheckResult> _scrapeRemoteAccessInfo() async {
  if (!Platform.isMacOS) {
    return new HealthCheckResult.success('${Platform.operatingSystem} not yet supported.');
  }

  String ip = (await eval('ipconfig', ['getifaddr', 'en0'], canFail: true)).trim();

  return new HealthCheckResult.success(ip.isEmpty
      ? 'No IP found for remote (SSH) access to this client. '
      'Did you forget to plug the Ethernet cable?'
      : 'Possible remote access IP: $ip'
  );
}
