// Copyright (c) 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../logic/agent_health_details.dart';
import 'now.dart';

/// An icon bar to display information from [AgentHealthDetails].
class AgentHealthDetailsBar extends StatelessWidget {
  const AgentHealthDetailsBar(
    this.healthDetails, {
    Key key,
  }) : super(key: key);

  final AgentHealthDetails healthDetails;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime now = Now.of(context);
    return Row(
      children: <Widget>[
        if (!healthDetails.pingedRecently(now))
          Tooltip(
            message: 'Agent timed out',
            child: Icon(Icons.timer, color: theme.errorColor),
          ),
        if (healthDetails.cocoonAuthentication)
          const Tooltip(
            message: 'Cocoon authentication passed',
            child: Icon(Icons.verified_user),
          )
        else
          Tooltip(
            message: 'Cocoon authentication failed',
            child: Icon(Icons.error, color: theme.errorColor),
          ),
        if (healthDetails.cocoonConnection)
          const Tooltip(
            message: 'Cocoon connected',
            child: Icon(Icons.network_wifi),
          )
        else
          Tooltip(
            message: 'Cocoon connection failed',
            child: Icon(Icons.perm_scan_wifi, color: theme.errorColor),
          ),
        if (healthDetails.hasHealthyDevices)
          const Tooltip(
            message: 'Devices healthy',
            child: Icon(Icons.devices),
          )
        else
          Tooltip(
            message: 'Devices not healthy',
            child: Icon(Icons.phonelink_erase, color: theme.errorColor),
          ),
      ],
    );
  }
}
