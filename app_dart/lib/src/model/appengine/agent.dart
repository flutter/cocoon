// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';
import 'package:json_annotation/json_annotation.dart';

import 'task.dart';

part 'agent.g.dart';

/// Class that represents a worker capable of running tasks.
@JsonSerializable(createFactory: false, ignoreUnannotated: true)
@Kind(name: 'Agent', idType: IdType.String)
class Agent extends Model {
  /// Creates a new [Agent].
  Agent({
    Key key,
    this.agentId,
    this.healthCheckTimestamp,
    this.isHealthy,
    this.isHidden = false,
    this.capabilities,
    this.healthDetails,
    this.authToken,
  }) {
    parentKey = key?.parent;
    id = key?.id;
  }

  /// The human-readable ID of the agent (e.g. 'linux1').
  @StringProperty(propertyName: 'AgentID', required: true)
  @JsonKey(name: 'AgentID')
  String agentId;

  /// The timestamp (in milliseconds since the Epoch) of the agent's last
  /// health check.
  @IntProperty(propertyName: 'HealthCheckTimestamp', required: true)
  @JsonKey(name: 'HealthCheckTimestamp')
  int healthCheckTimestamp;

  /// True iff the agent is currently marked as healthy.
  ///
  /// A healthy agent is capable of accepting tasks.
  @BoolProperty(propertyName: 'IsHealthy', required: true)
  @JsonKey(name: 'IsHealthy')
  bool isHealthy;

  @BoolProperty(propertyName: 'Hidden', required: true)
  bool isHidden;

  /// The list of capabilities that the agent supports.
  ///
  /// Capabilities are arbitrary string values, such as 'linux/android'. The
  /// capabilities of an agent will be matched up against the required
  /// capabilities of a devicelab task.
  ///
  /// See also:
  ///
  ///  * <https://github.com/flutter/flutter/blob/master/dev/devicelab/manifest.yaml>,
  ///    which lists "required_agent_capabilities" for each task therein.
  ///
  ///  * [Task.requiredCapabilities]
  @StringListProperty(propertyName: 'Capabilities')
  @JsonKey(name: 'Capabilities')
  List<String> capabilities;

  /// Freeform information about the agent that was reported during its last
  /// health check.
  ///
  /// This will include information such as the agent's host IP address.
  @StringProperty(propertyName: 'HealthDetails', indexed: false)
  @JsonKey(name: 'HealthDetails')
  String healthDetails;

  /// A hash of the agent's authentication token.
  ///
  /// This hash is generated using Provos and Mazières's bcrypt adaptive
  /// hashing algorithm. It should be decoded into ASCII, then used as
  /// the salt in the hashing function of the raw authentication token.
  ///
  /// See also:
  ///
  ///  * <https://www.usenix.org/legacy/event/usenix99/provos/provos.pdf>
  @BlobProperty(propertyName: 'AuthTokenHash')
  List<int> authToken;

  /// Tells whether this agent is capable of performing the specified [task].
  ///
  /// This is true iff every one of [task]s required capabilities exists in
  /// this agent's list of [capabilities].
  bool isCapableOfPerformingTask(Task task) =>
      task.requiredCapabilities.every((String capability) => capabilities.contains(capability));

  /// Serializes this object to a JSON primitive.
  Map<String, dynamic> toJson() => _$AgentToJson(this);

  @override
  String toString() {
    final StringBuffer buf = StringBuffer()
      ..write('$runtimeType(')
      ..write('id: $id')
      ..write(', parentKey: ${parentKey?.id}')
      ..write(', key: ${parentKey == null ? null : key.id}')
      ..write(', agentId: $agentId')
      ..write(', healthCheckTimestamp: $healthCheckTimestamp')
      ..write(', ${(isHealthy ?? false) ? 'healthy' : 'unhealthy'}')
      ..write(', ${(isHidden ?? false) ? 'hidden' : 'visible'}')
      ..write(', capabilities: $capabilities')
      ..write(')');
    return buf.toString();
  }
}
