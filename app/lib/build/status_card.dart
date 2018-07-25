// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:cocoon/models.dart';

/// A card to display the current status of an agent.
///
/// Every 30 seconds, this card will update the [lastHealthCheck]. This is
/// compared with the value of [AgentStatus.healthCheckTimestamp] to
/// determine the current status of the agent health.
///
/// To use this component, place a [ViewChild] annotation or ref in the parent
/// and then call [StatusCard.show] with the agent status to display.
@Component(
  selector: 'status-card',
  templateUrl: 'status_card.html',
  styleUrls: ['status_card.css'],
  directives: [NgIf],
  pipes: [AgentHealthPipe],
)
class StatusCard extends ComponentState implements OnInit, OnDestroy {
  AgentStatus agentStatus;
  Timer _updateHealthStatus;

  /// The last time the status of the agent was checked.
  DateTime get lastHealthCheck => _lastHealthCheck;
  DateTime _lastHealthCheck;

  /// An agent is considered healthy if the latest health report was OK and is
  /// up-to-date.
  bool get isAgentHealthy {
    return agentStatus.isHealthy &&
        agentStatus.healthCheckTimestamp != null &&
        _lastHealthCheck.difference(agentStatus.healthCheckTimestamp) <
            const Duration(minutes: 10);
  }

  @override
  void ngOnInit() {
    _updateHealthStatus =
        new Timer.periodic(const Duration(seconds: 30), _checkHealth);
  }

  @override
  void ngOnDestroy() {
    _updateHealthStatus?.cancel();
  }

  /// Open the agent status card and set [value] to the current [AgentStatus].
  void show(AgentStatus value) {
    agentStatus = value;
    deliverStateChanges();
  }

  /// Hide the agent status card.
  void hide() {
    agentStatus = null;
    deliverStateChanges();
  }

  void _checkHealth(Object _) {
    _lastHealthCheck = new DateTime.now();
    deliverStateChanges();
  }
}

/// A formatter to display the current age of an agent status check.
@Pipe('agent_health')
class AgentHealthPipe extends PipeTransform {
  String transform(DateTime dateTime, DateTime lastHealthCheck) {
    if (dateTime == null) return '';
    final age = lastHealthCheck.difference(dateTime);
    final qualifier =
        age > const Duration(minutes: 10) ? 'out-of-date!' : 'old';
    return '(${age.inMinutes} minutes $qualifier)';
  }
}
