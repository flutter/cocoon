// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../entities.dart';
import '../providers.dart';
import '../utils/framework.dart';
import '../utils/semantics.dart';

class AgentsPage extends StatelessWidget {
  const AgentsPage();

  @override
  Widget build(BuildContext context) {
    var buildStatusModel = BuildStatusProvider.of(context);
    return RequestOnce(
      callback: () {
        buildStatusModel.requestBuildStatus();
      },
      child: AgentsPageBody(
        agentStatuses: buildStatusModel.agentStatuses ?? const [],
        loaded: buildStatusModel.isLoaded,
      ),
    );
  }
}

class AgentsPageBody extends StatelessWidget {
  const AgentsPageBody({
    @required this.agentStatuses,
    @required this.loaded,
  });

  final List<AgentStatus> agentStatuses;
  final bool loaded;

  @override
  Widget build(BuildContext context) {
    var clockModel = ClockProvider.of(context);
    var slivers = <Widget>[
      SliverAppBar(
        title: const Text('Agents'),
        floating: true,
      ),
    ];
    if (loaded) {
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index.isOdd) {
                return const Divider(height: 1);
              }
              var status = agentStatuses[index ~/ 2];
              return AgentListTile(
                agentStatus: status,
                currentTime: clockModel.currentTime(),
              );
            },
            childCount: agentStatuses.length * 2,
            semanticIndexCallback: evenSemanticIndexes,
          ),
        ),
      );
    } else {
      slivers.add(
        const SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(semanticsLabel: 'Loading'),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(color: Theme.of(context).primaryColorDark),
      child: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(color: Theme.of(context).canvasColor),
          child: CustomScrollView(
            semanticChildCount: loaded ? agentStatuses.length : 1,
            slivers: slivers,
          ),
        ),
      ),
    );
  }
}

class AgentListTile extends StatelessWidget {
  const AgentListTile({
    @required this.agentStatus,
    @required this.currentTime,
  });

  final AgentStatus agentStatus;
  final DateTime currentTime;

  @override
  Widget build(BuildContext context) {
    var details = AgentHealthDetails(agentStatus.healthDetails);
    return ListTile(
      trailing: agentStatus.isHealthy
          ? Container(
              width: 36,
              height: 36,
              child: const Center(
                child: Text('H', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              decoration: BoxDecoration(border: Border.all()),
            )
          : Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(border: Border.all()),
              child: const Center(
                child: Text('F', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
      title: Text('${agentStatus.agentId}'),
      subtitle: Text('${details.ipAddress}\n'
          'Last updated at ${agentStatus.healthCheckTimestamp}'),
      isThreeLine: true,
      onTap: () {
        showDialog<void>(
            context: context,
            builder: (context) {
              return Dialog(
                  child: AgentDetailsPage(details: details),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)));
            });
      },
    );
  }
}

class StatusMark extends StatelessWidget {
  const StatusMark({this.successful});

  final bool successful;

  @override
  Widget build(BuildContext context) {
    if (successful) {
      return Container(
        alignment: Alignment.center,
        child: const Text('✓', style: TextStyle(fontSize: 18)),
        width: 32,
        height: 32,
      );
    }
    return Container(
      alignment: Alignment.center,
      child: const Text('x', style: TextStyle(fontSize: 18)),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.red[100],
      ),
    );
  }
}

class AgentDetailsPage extends StatelessWidget {
  const AgentDetailsPage({this.details});

  final AgentHealthDetails details;

  @override
  Widget build(BuildContext context) {
    var children = <TableRow>[
      TableRow(children: [
        const TableCell(child: Text('SSH connectivity', style: TextStyle(fontSize: 14))),
        TableCell(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: StatusMark(successful: details.hasSshConnectivity),
            ),
          ),
        ),
      ]),
      TableRow(children: [
        const TableCell(child: Text('Health Checkable', style: TextStyle(fontSize: 14))),
        TableCell(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: StatusMark(successful: details.canPerformHealthCheck),
            ),
          ),
        ),
      ]),
      TableRow(children: [
        const TableCell(child: Text('Cocoon Authentication', style: TextStyle(fontSize: 14))),
        TableCell(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: StatusMark(successful: details.cocoonAuthentication),
            ),
          ),
        ),
      ]),
      TableRow(children: [
        const TableCell(child: Text('Cocoon Connection', style: TextStyle(fontSize: 14))),
        TableCell(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: StatusMark(successful: details.cocoonConnection),
            ),
          ),
        ),
      ]),
      TableRow(children: [
        const TableCell(child: Text('Healthy Device', style: TextStyle(fontSize: 14))),
        TableCell(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: StatusMark(successful: details.hasHealthyDevices),
            ),
          ),
        ),
      ]),
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(),
          1: FixedColumnWidth(48),
        },
        children: children,
      ),
    );
  }
}

class AgentHealthDetails {
  factory AgentHealthDetails(String source) {
    var match = _ipAddress.firstMatch(source);
    return AgentHealthDetails._(
      match.group(0).split(': ')[1],
      source.contains(_hasHealthyDevices),
      source.contains(_cocoonAuthentication),
      source.contains(_cocoonConnection),
      source.contains(_ableToPerformhealthCheck),
      source.contains(_hasSshConnectivity),
    );
  }

  AgentHealthDetails._(
    this.ipAddress,
    this.hasHealthyDevices,
    this.cocoonAuthentication,
    this.cocoonConnection,
    this.canPerformHealthCheck,
    this.hasSshConnectivity,
  );

  static final _ipAddress = RegExp(r'Last known IP address: +\d+\.\d+\.\d+\.\d+');
  static final _hasSshConnectivity = RegExp('ssh-connectivity: succeeded');
  static final _hasHealthyDevices = RegExp('has-healthy-devices: succeeded');
  static final _cocoonAuthentication = RegExp('cocoon-authentication: succeeded');
  static final _cocoonConnection = RegExp('cocoon-connection: succeeded');
  static final _ableToPerformhealthCheck = RegExp('able-to-perform-health-check: succeeded');

  final String ipAddress;
  final bool hasHealthyDevices;
  final bool hasSshConnectivity;
  final bool cocoonAuthentication;
  final bool cocoonConnection;
  final bool canPerformHealthCheck;
}
