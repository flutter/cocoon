// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'build_pubsub.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Cipd _$CipdFromJson(Map<String, dynamic> json) => Cipd(
      package: json['package'] as String?,
      version: json['version'] as String?,
      server: json['server'] as String?,
      resolvedInstances: json['resolvedInstances'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$CipdToJson(Cipd instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('package', instance.package);
  writeNotNull('version', instance.version);
  writeNotNull('server', instance.server);
  writeNotNull('resolvedInstances', instance.resolvedInstances);
  return val;
}

Source _$SourceFromJson(Map<String, dynamic> json) => Source(
      cipd: json['cipd'] == null ? null : Cipd.fromJson(json['cipd'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SourceToJson(Source instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('cipd', instance.cipd);
  return val;
}

Cas _$CasFromJson(Map<String, dynamic> json) => Cas(
      casInstance: json['casInstance'] as String?,
      digest: json['digest'] == null ? null : Digest.fromJson(json['digest'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CasToJson(Cas instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('casInstance', instance.casInstance);
  writeNotNull('digest', instance.digest);
  return val;
}

Digest _$DigestFromJson(Map<String, dynamic> json) => Digest(
      hash: json['hash'] as String?,
      sizeBytes: json['sizeBytes'] as int?,
    );

Map<String, dynamic> _$DigestToJson(Digest instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('hash', instance.hash);
  writeNotNull('sizeBytes', instance.sizeBytes);
  return val;
}

InputDataRefPackageSpec _$InputDataRefPackageSpecFromJson(Map<String, dynamic> json) => InputDataRefPackageSpec(
      package: json['package'] as String?,
      version: json['version'] as String?,
    );

Map<String, dynamic> _$InputDataRefPackageSpecToJson(InputDataRefPackageSpec instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('package', instance.package);
  writeNotNull('version', instance.version);
  return val;
}

InputDataRefCipd _$InputDataRefCipdFromJson(Map<String, dynamic> json) => InputDataRefCipd(
      server: json['server'] as String?,
      specs: (json['specs'] as List<dynamic>?)
          ?.map((e) => InputDataRefPackageSpec.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$InputDataRefCipdToJson(InputDataRefCipd instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('server', instance.server);
  writeNotNull('specs', instance.specs);
  return val;
}

InputDataRef _$InputDataRefFromJson(Map<String, dynamic> json) => InputDataRef(
      cas: json['cas'] == null ? null : Cas.fromJson(json['cas'] as Map<String, dynamic>),
      cipd: json['cipd'] == null ? null : InputDataRefCipd.fromJson(json['cipd'] as Map<String, dynamic>),
      onPath: (json['onPath'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$InputDataRefToJson(InputDataRef instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('cas', instance.cas);
  writeNotNull('cipd', instance.cipd);
  writeNotNull('onPath', instance.onPath);
  return val;
}

ResolvedDataRefTiming _$ResolvedDataRefTimingFromJson(Map<String, dynamic> json) => ResolvedDataRefTiming(
      fetchDuration: json['fetchDuration'] == null ? null : Duration(microseconds: json['fetchDuration'] as int),
      installDuration: json['installDuration'] == null ? null : Duration(microseconds: json['installDuration'] as int),
    );

Map<String, dynamic> _$ResolvedDataRefTimingToJson(ResolvedDataRefTiming instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('fetchDuration', instance.fetchDuration?.inMicroseconds);
  writeNotNull('installDuration', instance.installDuration?.inMicroseconds);
  return val;
}

ResolvedDataRefCipd _$ResolvedDataRefCipdFromJson(Map<String, dynamic> json) => ResolvedDataRefCipd(
      specs: (json['specs'] as List<dynamic>?)
          ?.map((e) => ResolvedDataRefPackageSpec.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ResolvedDataRefCipdToJson(ResolvedDataRefCipd instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('specs', instance.specs);
  return val;
}

ResolvedDataRefCas _$ResolvedDataRefCasFromJson(Map<String, dynamic> json) => ResolvedDataRefCas(
      timing: json['timing'] == null ? null : ResolvedDataRefTiming.fromJson(json['timing'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ResolvedDataRefCasToJson(ResolvedDataRefCas instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('timing', instance.timing);
  return val;
}

ResolvedDataRefPackageSpec _$ResolvedDataRefPackageSpecFromJson(Map<String, dynamic> json) =>
    ResolvedDataRefPackageSpec(
      skipped: json['skipped'] as bool?,
      package: json['package'] as String?,
      version: json['version'] as String?,
      wasCached: $enumDecodeNullable(_$TrinaryEnumMap, json['wasCached']),
      timing: json['timing'] == null ? null : ResolvedDataRefTiming.fromJson(json['timing'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ResolvedDataRefPackageSpecToJson(ResolvedDataRefPackageSpec instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('skipped', instance.skipped);
  writeNotNull('package', instance.package);
  writeNotNull('version', instance.version);
  writeNotNull('wasCached', _$TrinaryEnumMap[instance.wasCached]);
  writeNotNull('timing', instance.timing);
  return val;
}

const _$TrinaryEnumMap = {
  Trinary.yes: 'YES',
  Trinary.no: 'NO',
  Trinary.unset: 'UNSET',
};

ResolvedDataRef _$ResolvedDataRefFromJson(Map<String, dynamic> json) => ResolvedDataRef(
      cipd: json['cipd'] == null ? null : ResolvedDataRefCipd.fromJson(json['cipd'] as Map<String, dynamic>),
      cas: json['cas'] == null ? null : ResolvedDataRefCas.fromJson(json['cas'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ResolvedDataRefToJson(ResolvedDataRef instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('cipd', instance.cipd);
  writeNotNull('cas', instance.cas);
  return val;
}

AgentInput _$AgentInputFromJson(Map<String, dynamic> json) => AgentInput(
      (json['data'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, InputDataRef.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$AgentInputToJson(AgentInput instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('data', instance.data);
  return val;
}

AgentOutput _$AgentOutputFromJson(Map<String, dynamic> json) => AgentOutput(
      resolvedData: (json['resolvedData'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, ResolvedDataRef.fromJson(e as Map<String, dynamic>)),
      ),
      status: $enumDecodeNullable(_$StatusEnumMap, json['status']),
      summaryHtml: json['summaryHtml'] as String?,
      agentPlatform: json['agentPlatform'] as String?,
      totalDuration: json['totalDuration'] == null ? null : Duration(microseconds: json['totalDuration'] as int),
    );

Map<String, dynamic> _$AgentOutputToJson(AgentOutput instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('resolvedData', instance.resolvedData);
  writeNotNull('status', _$StatusEnumMap[instance.status]);
  writeNotNull('summaryHtml', instance.summaryHtml);
  writeNotNull('agentPlatform', instance.agentPlatform);
  writeNotNull('totalDuration', instance.totalDuration?.inMicroseconds);
  return val;
}

const _$StatusEnumMap = {
  Status.unspecified: 'STATUS_UNSPECIFIED',
  Status.scheduled: 'SCHEDULED',
  Status.started: 'STARTED',
  Status.ended: 'ENDED_MASK',
  Status.success: 'SUCCESS',
  Status.failure: 'FAILURE',
  Status.infraFailure: 'INFRA_FAILURE',
  Status.canceled: 'CANCELED',
};

Agent _$AgentFromJson(Map<String, dynamic> json) => Agent(
      input: json['input'] == null ? null : AgentInput.fromJson(json['input'] as Map<String, dynamic>),
      output: json['output'] == null ? null : AgentOutput.fromJson(json['output'] as Map<String, dynamic>),
      source: json['source'] == null ? null : Source.fromJson(json['source'] as Map<String, dynamic>),
      purposes: (json['purposes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, $enumDecode(_$PurposeEnumMap, e)),
      ),
    );

Map<String, dynamic> _$AgentToJson(Agent instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('input', instance.input);
  writeNotNull('output', instance.output);
  writeNotNull('source', instance.source);
  writeNotNull('purposes', instance.purposes?.map((k, e) => MapEntry(k, _$PurposeEnumMap[e]!)));
  return val;
}

const _$PurposeEnumMap = {
  Purpose.purposeUnspecified: 'PURPOSE_UNSPECIFIED',
  Purpose.purposeExePayload: 'PURPOSE_EXE_PAYLOAD',
  Purpose.purposeBbAgentUtility: 'PURPOSE_BBAGENT_UTILITY',
};

BuildBucket _$BuildBucketFromJson(Map<String, dynamic> json) => BuildBucket(
      serviceConfigRevision: json['serviceConfigRevision'] as String?,
      requestedProperties: (json['requestedProperties'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as Object),
      ),
      requestedDimensions: (json['requestedDimensions'] as List<dynamic>?)
          ?.map((e) => RequestedDimension.fromJson(e as Map<String, dynamic>))
          .toList(),
      hostname: json['hostname'] as String?,
      experimentReasons: (json['experimentReasons'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, $enumDecode(_$ExperimentReasonEnumMap, e)),
      ),
      agentExecutable: (json['agentExecutable'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, ResolvedDataRef.fromJson(e as Map<String, dynamic>)),
      ),
      agent: json['agent'] == null ? null : Agent.fromJson(json['agent'] as Map<String, dynamic>),
      knownPublicGerritHosts: (json['knownPublicGerritHosts'] as List<dynamic>?)?.map((e) => e as String).toList(),
      buildNumber: json['buildNumber'] as bool?,
    );

Map<String, dynamic> _$BuildBucketToJson(BuildBucket instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('serviceConfigRevision', instance.serviceConfigRevision);
  writeNotNull('requestedProperties', instance.requestedProperties);
  writeNotNull('requestedDimensions', instance.requestedDimensions);
  writeNotNull('hostname', instance.hostname);
  writeNotNull(
      'experimentReasons', instance.experimentReasons?.map((k, e) => MapEntry(k, _$ExperimentReasonEnumMap[e]!)));
  writeNotNull('agentExecutable', instance.agentExecutable);
  writeNotNull('agent', instance.agent);
  writeNotNull('knownPublicGerritHosts', instance.knownPublicGerritHosts);
  writeNotNull('buildNumber', instance.buildNumber);
  return val;
}

const _$ExperimentReasonEnumMap = {
  ExperimentReason.experimentReasonUnset: 'EXPERIMENT_REASON_UNSET',
  ExperimentReason.experimentReasonGlobalDefault: 'EXPERIMENT_REASON_GLOBAL_DEFAULT',
  ExperimentReason.experimentReasonBuilderConfig: 'EXPERIMENT_REASON_BUILDER_CONFIG',
  ExperimentReason.experimentReasonGlobalMinimum: 'EXPERIMENT_REASON_GLOBAL_MINIMUM',
  ExperimentReason.experimentReasonRequested: 'EXPERIMENT_REASON_REQUESTED',
  ExperimentReason.experimentReasonGlobalInactive: 'EXPERIMENT_REASON_GLOBAL_INACTIVE',
};

CacheEntry _$CacheEntryFromJson(Map<String, dynamic> json) => CacheEntry(
      name: json['name'] as String?,
      path: json['path'] as String?,
      waitForWarmCache: json['waitForWarmCache'] as String?,
      envVar: json['envVar'] as String?,
    );

Map<String, dynamic> _$CacheEntryToJson(CacheEntry instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  writeNotNull('path', instance.path);
  writeNotNull('waitForWarmCache', instance.waitForWarmCache);
  writeNotNull('envVar', instance.envVar);
  return val;
}

Swarming _$SwarmingFromJson(Map<String, dynamic> json) => Swarming(
      hostname: json['hostname'] as String?,
      taskId: json['taskId'] as String?,
      parentRunId: json['parentRunId'] as String?,
      taskServiceAccount: json['taskServiceAccount'] as String?,
      priority: json['priority'] as int?,
      taskDimensions: (json['taskDimensions'] as List<dynamic>?)
          ?.map((e) => RequestedDimension.fromJson(e as Map<String, dynamic>))
          .toList(),
      botDimensions: (json['botDimensions'] as List<dynamic>?)
          ?.map((e) => StringPair.fromJson(e as Map<String, dynamic>))
          .toList(),
      caches: (json['caches'] as List<dynamic>?)?.map((e) => CacheEntry.fromJson(e as Map<String, dynamic>)).toList(),
    );

Map<String, dynamic> _$SwarmingToJson(Swarming instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('hostname', instance.hostname);
  writeNotNull('taskId', instance.taskId);
  writeNotNull('parentRunId', instance.parentRunId);
  writeNotNull('taskServiceAccount', instance.taskServiceAccount);
  writeNotNull('priority', instance.priority);
  writeNotNull('taskDimensions', instance.taskDimensions);
  writeNotNull('botDimensions', instance.botDimensions);
  writeNotNull('caches', instance.caches);
  return val;
}

Recipe _$RecipeFromJson(Map<String, dynamic> json) => Recipe(
      cipdPackage: json['cipdPackage'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$RecipeToJson(Recipe instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('cipdPackage', instance.cipdPackage);
  writeNotNull('name', instance.name);
  return val;
}

InputCipdPackage _$InputCipdPackageFromJson(Map<String, dynamic> json) => InputCipdPackage(
      name: json['name'] as String?,
      version: json['version'] as String?,
      server: json['server'] as String?,
      path: json['path'] as String?,
    );

Map<String, dynamic> _$InputCipdPackageToJson(InputCipdPackage instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  writeNotNull('version', instance.version);
  writeNotNull('server', instance.server);
  writeNotNull('path', instance.path);
  return val;
}

BBAgentInput _$BBAgentInputFromJson(Map<String, dynamic> json) => BBAgentInput(
      cipdPackages: (json['cipdPackages'] as List<dynamic>?)
          ?.map((e) => InputCipdPackage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BBAgentInputToJson(BBAgentInput instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('cipdPackages', instance.cipdPackages);
  return val;
}

BBAgent _$BBAgentFromJson(Map<String, dynamic> json) => BBAgent(
      payloadPath: json['payloadPath'] as String?,
      cacheDir: json['cacheDir'] as String?,
      knownPublicGerritHosts: (json['knownPublicGerritHosts'] as List<dynamic>?)?.map((e) => e as String).toList(),
      input: json['input'] == null ? null : BBAgentInput.fromJson(json['input'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BBAgentToJson(BBAgent instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('payloadPath', instance.payloadPath);
  writeNotNull('cacheDir', instance.cacheDir);
  writeNotNull('knownPublicGerritHosts', instance.knownPublicGerritHosts);
  writeNotNull('input', instance.input);
  return val;
}

Backend _$BackendFromJson(Map<String, dynamic> json) => Backend(
      config: (json['config'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as Object),
      ),
      task: json['task'] == null ? null : BuildBucketTask.fromJson(json['task'] as Map<String, dynamic>),
      caches: (json['caches'] as List<dynamic>?)?.map((e) => CacheEntry.fromJson(e as Map<String, dynamic>)).toList(),
      taskDimensions: (json['taskDimensions'] as List<dynamic>?)
          ?.map((e) => RequestedDimension.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BackendToJson(Backend instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('config', instance.config);
  writeNotNull('task', instance.task);
  writeNotNull('caches', instance.caches);
  writeNotNull('taskDimensions', instance.taskDimensions);
  return val;
}

BuildInfra _$BuildInfraFromJson(Map<String, dynamic> json) => BuildInfra(
      buildBucket:
          json['buildbucket'] == null ? null : BuildBucket.fromJson(json['buildbucket'] as Map<String, dynamic>),
      swarming: json['swarming'] == null ? null : Swarming.fromJson(json['swarming'] as Map<String, dynamic>),
      recipe: json['recipe'] == null ? null : Recipe.fromJson(json['recipe'] as Map<String, dynamic>),
      bbAgent: json['bbagent'] == null ? null : BBAgent.fromJson(json['bbagent'] as Map<String, dynamic>),
      backend: json['backend'] == null ? null : Backend.fromJson(json['backend'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuildInfraToJson(BuildInfra instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('buildbucket', instance.buildBucket);
  writeNotNull('swarming', instance.swarming);
  writeNotNull('recipe', instance.recipe);
  writeNotNull('bbagent', instance.bbAgent);
  writeNotNull('backend', instance.backend);
  return val;
}

RequestedDimension _$RequestedDimensionFromJson(Map<String, dynamic> json) => RequestedDimension(
      key: json['key'] as String?,
      value: json['value'] as String?,
      expiration: json['expiration'] as String?,
    );

Map<String, dynamic> _$RequestedDimensionToJson(RequestedDimension instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('key', instance.key);
  writeNotNull('value', instance.value);
  writeNotNull('expiration', instance.expiration);
  return val;
}

StringPair _$StringPairFromJson(Map<String, dynamic> json) => StringPair(
      key: json['key'] as String?,
      value: json['value'] as String?,
    );

Map<String, dynamic> _$StringPairToJson(StringPair instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('key', instance.key);
  writeNotNull('value', instance.value);
  return val;
}

TaskId _$TaskIdFromJson(Map<String, dynamic> json) => TaskId(
      target: json['target'] as String?,
      id: json['id'] as String?,
    );

Map<String, dynamic> _$TaskIdToJson(TaskId instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('target', instance.target);
  writeNotNull('id', instance.id);
  return val;
}

BuildBucketTask _$BuildBucketTaskFromJson(Map<String, dynamic> json) => BuildBucketTask(
      taskId: json['taskId'] == null ? null : TaskId.fromJson(json['taskId'] as Map<String, dynamic>),
      link: json['link'] as String?,
      status: $enumDecodeNullable(_$StatusEnumMap, json['status']),
      summaryHtml: json['summaryHtml'] as String?,
      updateId: json['updateId'] as int?,
      details: (json['details'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as Object),
      ),
    );

Map<String, dynamic> _$BuildBucketTaskToJson(BuildBucketTask instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('taskId', instance.taskId);
  writeNotNull('link', instance.link);
  writeNotNull('status', _$StatusEnumMap[instance.status]);
  writeNotNull('summaryHtml', instance.summaryHtml);
  writeNotNull('updateId', instance.updateId);
  writeNotNull('details', instance.details);
  return val;
}

BuilderId _$BuilderIdFromJson(Map<String, dynamic> json) => BuilderId(
      project: json['project'] as String?,
      bucket: json['bucket'] as String?,
      builder: json['builder'] as String?,
    );

Map<String, dynamic> _$BuilderIdToJson(BuilderId instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('project', instance.project);
  writeNotNull('bucket', instance.bucket);
  writeNotNull('builder', instance.builder);
  return val;
}

BuilderInfo _$BuilderInfoFromJson(Map<String, dynamic> json) => BuilderInfo(
      description: json['description'] as String?,
    );

Map<String, dynamic> _$BuilderInfoToJson(BuilderInfo instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('description', instance.description);
  return val;
}

GitilesCommit _$GitilesCommitFromJson(Map<String, dynamic> json) => GitilesCommit(
      host: json['host'] as String?,
      project: json['project'] as String?,
      ref: json['ref'] as String?,
      hash: json['id'] as String?,
    );

Map<String, dynamic> _$GitilesCommitToJson(GitilesCommit instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('host', instance.host);
  writeNotNull('project', instance.project);
  writeNotNull('id', instance.hash);
  writeNotNull('ref', instance.ref);
  return val;
}

Input _$InputFromJson(Map<String, dynamic> json) => Input(
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as Object),
      ),
      gitilesCommit:
          json['gitilesCommit'] == null ? null : GitilesCommit.fromJson(json['gitilesCommit'] as Map<String, dynamic>),
      experimental: json['experimental'] as bool?,
    );

Map<String, dynamic> _$InputToJson(Input instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('properties', instance.properties);
  writeNotNull('gitilesCommit', instance.gitilesCommit);
  writeNotNull('experimental', instance.experimental);
  return val;
}

Executable _$ExecutableFromJson(Map<String, dynamic> json) => Executable(
      cipdPackage: json['cipdPackage'] as String?,
      cipdVersion: json['cipdVersion'] as String?,
      cmd: (json['cmd'] as List<dynamic>?)?.map((e) => e as String).toList(),
      wrapper: (json['wrapper'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ExecutableToJson(Executable instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('cipdPackage', instance.cipdPackage);
  writeNotNull('cipdVersion', instance.cipdVersion);
  writeNotNull('cmd', instance.cmd);
  writeNotNull('wrapper', instance.wrapper);
  return val;
}

Output _$OutputFromJson(Map<String, dynamic> json) => Output(
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as Object),
      ),
      gitilesCommit:
          json['gitilesCommit'] == null ? null : GitilesCommit.fromJson(json['gitilesCommit'] as Map<String, dynamic>),
      status: $enumDecodeNullable(_$StatusEnumMap, json['status']),
      summaryHtml: json['summaryHtml'] as String?,
    );

Map<String, dynamic> _$OutputToJson(Output instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('properties', instance.properties);
  writeNotNull('gitilesCommit', instance.gitilesCommit);
  writeNotNull('status', _$StatusEnumMap[instance.status]);
  writeNotNull('summaryHtml', instance.summaryHtml);
  return val;
}

MergeBuild _$MergeBuildFromJson(Map<String, dynamic> json) => MergeBuild(
      fromLogDogStream: json['fromLogDogStream'] as String?,
      legacyGlobalNamespace: json['legacyGlobalNamespace'] as bool?,
    );

Map<String, dynamic> _$MergeBuildToJson(MergeBuild instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('fromLogDogStream', instance.fromLogDogStream);
  writeNotNull('legacyGlobalNamespace', instance.legacyGlobalNamespace);
  return val;
}

Step _$StepFromJson(Map<String, dynamic> json) => Step(
      name: json['name'] as String?,
      startTime: json['startTime'] == null ? null : DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null ? null : DateTime.parse(json['endTime'] as String),
      status: $enumDecodeNullable(_$StatusEnumMap, json['status']),
      summaryMarkdown: json['summaryMarkdown'] as String?,
      tags: const TagsConverter().fromJson(json['tags'] as List?),
    );

Map<String, dynamic> _$StepToJson(Step instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  writeNotNull('startTime', instance.startTime?.toIso8601String());
  writeNotNull('endTime', instance.endTime?.toIso8601String());
  writeNotNull('status', _$StatusEnumMap[instance.status]);
  writeNotNull('summaryMarkdown', instance.summaryMarkdown);
  writeNotNull('tags', const TagsConverter().toJson(instance.tags));
  return val;
}

Build _$BuildFromJson(Map<String, dynamic> json) => Build(
      id: json['id'] as String?,
      builder: json['builder'] == null ? null : BuilderId.fromJson(json['builder'] as Map<String, dynamic>),
      builderInfo:
          json['builderInfo'] == null ? null : BuilderInfo.fromJson(json['builderInfo'] as Map<String, dynamic>),
      number: json['number'] as int?,
      createdBy: json['createdBy'] as String?,
      canceledBy: json['canceledBy'] as String?,
      createTime: json['createTime'] == null ? null : DateTime.parse(json['createTime'] as String),
      startTime: json['startTime'] == null ? null : DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null ? null : DateTime.parse(json['endTime'] as String),
      updateTime: json['updateTime'] == null ? null : DateTime.parse(json['updateTime'] as String),
      cancelTime: json['cancelTime'] == null ? null : DateTime.parse(json['cancelTime'] as String),
      status: $enumDecodeNullable(_$StatusEnumMap, json['status']),
      summaryMarkdown: json['summaryMarkdown'] as String?,
      cancellationMarkdown: json['cancellationMarkdown'] as String?,
      critical: $enumDecodeNullable(_$TrinaryEnumMap, json['critical']),
      input: json['input'] == null ? null : Input.fromJson(json['input'] as Map<String, dynamic>),
      output: json['output'] == null ? null : Output.fromJson(json['output'] as Map<String, dynamic>),
      steps: (json['steps'] as List<dynamic>?)?.map((e) => Step.fromJson(e as Map<String, dynamic>)).toList(),
      buildInfra: json['infra'] == null ? null : BuildInfra.fromJson(json['infra'] as Map<String, dynamic>),
      tags: const TagsConverter().fromJson(json['tags'] as List?),
      exe: json['exe'] == null ? null : Executable.fromJson(json['exe'] as Map<String, dynamic>),
      canary: json['canary'] as bool?,
      schedulingTimeout: json['schedulingTimeout'] as String?,
      executionTimeout: json['executionTimeout'] as String?,
      gracePeriod: json['gracePeriod'] as String?,
      waitForCapacity: json['waitForCapacity'] as bool?,
      canOutliveParent: json['canOutliveParent'] as bool?,
      ancestorIds: (json['ancestorIds'] as List<dynamic>?)?.map((e) => e as int).toList(),
      retriable: $enumDecodeNullable(_$TrinaryEnumMap, json['retriable']),
    );

Map<String, dynamic> _$BuildToJson(Build instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  writeNotNull('builder', instance.builder);
  writeNotNull('builderInfo', instance.builderInfo);
  writeNotNull('number', instance.number);
  writeNotNull('createdBy', instance.createdBy);
  writeNotNull('canceledBy', instance.canceledBy);
  writeNotNull('createTime', instance.createTime?.toIso8601String());
  writeNotNull('startTime', instance.startTime?.toIso8601String());
  writeNotNull('endTime', instance.endTime?.toIso8601String());
  writeNotNull('updateTime', instance.updateTime?.toIso8601String());
  writeNotNull('cancelTime', instance.cancelTime?.toIso8601String());
  writeNotNull('status', _$StatusEnumMap[instance.status]);
  writeNotNull('summaryMarkdown', instance.summaryMarkdown);
  writeNotNull('cancellationMarkdown', instance.cancellationMarkdown);
  writeNotNull('critical', _$TrinaryEnumMap[instance.critical]);
  writeNotNull('input', instance.input);
  writeNotNull('output', instance.output);
  writeNotNull('steps', instance.steps);
  writeNotNull('infra', instance.buildInfra);
  writeNotNull('tags', const TagsConverter().toJson(instance.tags));
  writeNotNull('exe', instance.exe);
  writeNotNull('canary', instance.canary);
  writeNotNull('schedulingTimeout', instance.schedulingTimeout);
  writeNotNull('executionTimeout', instance.executionTimeout);
  writeNotNull('gracePeriod', instance.gracePeriod);
  writeNotNull('waitForCapacity', instance.waitForCapacity);
  writeNotNull('canOutliveParent', instance.canOutliveParent);
  writeNotNull('ancestorIds', instance.ancestorIds);
  writeNotNull('retriable', _$TrinaryEnumMap[instance.retriable]);
  return val;
}

BuildV2PubSub _$BuildV2PubSubFromJson(Map<String, dynamic> json) => BuildV2PubSub(
      build: json['build'] == null ? null : Build.fromJson(json['build'] as Map<String, dynamic>),
      compression: $enumDecodeNullable(_$CompressionEnumMap, json['compression']),
    );

Map<String, dynamic> _$BuildV2PubSubToJson(BuildV2PubSub instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('build', instance.build);
  writeNotNull('compression', _$CompressionEnumMap[instance.compression]);
  return val;
}

const _$CompressionEnumMap = {
  Compression.zlib: 'ZLIB',
  Compression.zstd: 'ZSTD',
};

PubSubCallBack _$PubSubCallBackFromJson(Map<String, dynamic> json) => PubSubCallBack(
      buildV2PubSub:
          json['buildV2PubSub'] == null ? null : BuildV2PubSub.fromJson(json['buildV2PubSub'] as Map<String, dynamic>),
      userData: json['userData'] as String?,
    );

Map<String, dynamic> _$PubSubCallBackToJson(PubSubCallBack instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('buildV2PubSub', instance.buildV2PubSub);
  val['userData'] = instance.userData;
  return val;
}
