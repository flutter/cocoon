// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'build_infra.dart';

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
      cipd: json['cipd'] == null
          ? null
          : Cipd.fromJson(json['cipd'] as Map<String, dynamic>),
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
      digest: json['digest'] == null
          ? null
          : Digest.fromJson(json['digest'] as Map<String, dynamic>),
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

InputDataRefPackageSpec _$InputDataRefPackageSpecFromJson(
        Map<String, dynamic> json) =>
    InputDataRefPackageSpec(
      package: json['package'] as String?,
      version: json['version'] as String?,
    );

Map<String, dynamic> _$InputDataRefPackageSpecToJson(
    InputDataRefPackageSpec instance) {
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

InputDataRefCipd _$InputDataRefCipdFromJson(Map<String, dynamic> json) =>
    InputDataRefCipd(
      server: json['server'] as String?,
      specs: (json['specs'] as List<dynamic>?)
          ?.map((e) =>
              InputDataRefPackageSpec.fromJson(e as Map<String, dynamic>))
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
      cas: json['cas'] == null
          ? null
          : Cas.fromJson(json['cas'] as Map<String, dynamic>),
      cipd: json['cipd'] == null
          ? null
          : InputDataRefCipd.fromJson(json['cipd'] as Map<String, dynamic>),
      onPath:
          (json['onPath'] as List<dynamic>?)?.map((e) => e as String).toList(),
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

ResolvedDataRefTiming _$ResolvedDataRefTimingFromJson(
        Map<String, dynamic> json) =>
    ResolvedDataRefTiming(
      fetchDuration: json['fetchDuration'] == null
          ? null
          : Duration(microseconds: json['fetchDuration'] as int),
      installDuration: json['installDuration'] == null
          ? null
          : Duration(microseconds: json['installDuration'] as int),
    );

Map<String, dynamic> _$ResolvedDataRefTimingToJson(
    ResolvedDataRefTiming instance) {
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

ResolvedDataRefCipd _$ResolvedDataRefCipdFromJson(Map<String, dynamic> json) =>
    ResolvedDataRefCipd(
      specs: (json['specs'] as List<dynamic>?)
          ?.map((e) =>
              ResolvedDataRefPackageSpec.fromJson(e as Map<String, dynamic>))
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

ResolvedDataRefCas _$ResolvedDataRefCasFromJson(Map<String, dynamic> json) =>
    ResolvedDataRefCas(
      timing: json['timing'] == null
          ? null
          : ResolvedDataRefTiming.fromJson(
              json['timing'] as Map<String, dynamic>),
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

ResolvedDataRefPackageSpec _$ResolvedDataRefPackageSpecFromJson(
        Map<String, dynamic> json) =>
    ResolvedDataRefPackageSpec(
      skipped: json['skipped'] as bool?,
      package: json['package'] as String?,
      version: json['version'] as String?,
      wasCached: $enumDecodeNullable(_$TrinaryEnumMap, json['wasCached']),
      timing: json['timing'] == null
          ? null
          : ResolvedDataRefTiming.fromJson(
              json['timing'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ResolvedDataRefPackageSpecToJson(
    ResolvedDataRefPackageSpec instance) {
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

ResolvedDataRef _$ResolvedDataRefFromJson(Map<String, dynamic> json) =>
    ResolvedDataRef(
      cipd: json['cipd'] == null
          ? null
          : ResolvedDataRefCipd.fromJson(json['cipd'] as Map<String, dynamic>),
      cas: json['cas'] == null
          ? null
          : ResolvedDataRefCas.fromJson(json['cas'] as Map<String, dynamic>),
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
        (k, e) =>
            MapEntry(k, ResolvedDataRef.fromJson(e as Map<String, dynamic>)),
      ),
      status: $enumDecodeNullable(_$StatusEnumMap, json['status']),
      summaryHtml: json['summaryHtml'] as String?,
      agentPlatform: json['agentPlatform'] as String?,
      totalDuration: json['totalDuration'] == null
          ? null
          : Duration(microseconds: json['totalDuration'] as int),
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
      input: json['input'] == null
          ? null
          : AgentInput.fromJson(json['input'] as Map<String, dynamic>),
      output: json['output'] == null
          ? null
          : AgentOutput.fromJson(json['output'] as Map<String, dynamic>),
      source: json['source'] == null
          ? null
          : Source.fromJson(json['source'] as Map<String, dynamic>),
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
  writeNotNull('purposes',
      instance.purposes?.map((k, e) => MapEntry(k, _$PurposeEnumMap[e]!)));
  return val;
}

const _$PurposeEnumMap = {
  Purpose.purposeUnspecified: 'PURPOSE_UNSPECIFIED',
  Purpose.purposeExePayload: 'PURPOSE_EXE_PAYLOAD',
  Purpose.purposeBbAgentUtility: 'PURPOSE_BBAGENT_UTILITY',
};

BuildBucket _$BuildBucketFromJson(Map<String, dynamic> json) => BuildBucket(
      serviceConfigRevision: json['serviceConfigRevision'] as String?,
      requestedProperties:
          (json['requestedProperties'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as Object),
      ),
      requestedDimensions: (json['requestedDimensions'] as List<dynamic>?)
          ?.map((e) => RequestedDimension.fromJson(e as Map<String, dynamic>))
          .toList(),
      hostname: json['hostname'] as String?,
      experimentReasons:
          (json['experimentReasons'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, $enumDecode(_$ExperimentReasonEnumMap, e)),
      ),
      agentExecutable: (json['agentExecutable'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, ResolvedDataRef.fromJson(e as Map<String, dynamic>)),
      ),
      agent: json['agent'] == null
          ? null
          : Agent.fromJson(json['agent'] as Map<String, dynamic>),
      knownPublicGerritHosts: (json['knownPublicGerritHosts'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
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
      'experimentReasons',
      instance.experimentReasons
          ?.map((k, e) => MapEntry(k, _$ExperimentReasonEnumMap[e]!)));
  writeNotNull('agentExecutable', instance.agentExecutable);
  writeNotNull('agent', instance.agent);
  writeNotNull('knownPublicGerritHosts', instance.knownPublicGerritHosts);
  writeNotNull('buildNumber', instance.buildNumber);
  return val;
}

const _$ExperimentReasonEnumMap = {
  ExperimentReason.experimentReasonUnset: 'EXPERIMENT_REASON_UNSET',
  ExperimentReason.experimentReasonGlobalDefault:
      'EXPERIMENT_REASON_GLOBAL_DEFAULT',
  ExperimentReason.experimentReasonBuilderConfig:
      'EXPERIMENT_REASON_BUILDER_CONFIG',
  ExperimentReason.experimentReasonGlobalMinimum:
      'EXPERIMENT_REASON_GLOBAL_MINIMUM',
  ExperimentReason.experimentReasonRequested: 'EXPERIMENT_REASON_REQUESTED',
  ExperimentReason.experimentReasonGlobalInactive:
      'EXPERIMENT_REASON_GLOBAL_INACTIVE',
};

CacheEntry _$CacheEntryFromJson(Map<String, dynamic> json) => CacheEntry(
      name: json['name'] as String?,
      path: json['path'] as String?,
      waitForWarmCache: json['waitForWarmCache'] == null
          ? null
          : Duration(microseconds: json['waitForWarmCache'] as int),
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
  writeNotNull('waitForWarmCache', instance.waitForWarmCache?.inMicroseconds);
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
      caches: (json['caches'] as List<dynamic>?)
          ?.map((e) => CacheEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
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

InputCipdPackage _$InputCipdPackageFromJson(Map<String, dynamic> json) =>
    InputCipdPackage(
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
      knownPublicGerritHosts: (json['knownPublicGerritHosts'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      input: json['input'] == null
          ? null
          : BBAgentInput.fromJson(json['input'] as Map<String, dynamic>),
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
      task: json['task'] == null
          ? null
          : Task.fromJson(json['task'] as Map<String, dynamic>),
      caches: (json['caches'] as List<dynamic>?)
          ?.map((e) => CacheEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      buildBucket: json['buildBucket'] == null
          ? null
          : BuildBucket.fromJson(json['buildBucket'] as Map<String, dynamic>),
      swarming: json['swarming'] == null
          ? null
          : Swarming.fromJson(json['swarming'] as Map<String, dynamic>),
      recipe: json['recipe'] == null
          ? null
          : Recipe.fromJson(json['recipe'] as Map<String, dynamic>),
      bbAgent: json['bbAgent'] == null
          ? null
          : BBAgent.fromJson(json['bbAgent'] as Map<String, dynamic>),
      backend: json['backend'] == null
          ? null
          : Backend.fromJson(json['backend'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuildInfraToJson(BuildInfra instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('buildBucket', instance.buildBucket);
  writeNotNull('swarming', instance.swarming);
  writeNotNull('recipe', instance.recipe);
  writeNotNull('bbAgent', instance.bbAgent);
  writeNotNull('backend', instance.backend);
  return val;
}
