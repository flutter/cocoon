import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:json_annotation/json_annotation.dart';

import 'buildbucket.dart' as build_bucket;

part 'build_infra.g.dart';

// BuildInfra/Buildbucket/Agent/Souce
@JsonSerializable(includeIfNull: false)
class Cipd extends JsonBody {
  const Cipd({
    this.package,
    this.version,
    this.server,
    this.resolvedInstances,
  });

  final String? package;
  final String? version;
  final String? server;
  final Map<String, dynamic>? resolvedInstances;

  @override
  Map<String, dynamic> toJson() => _$CipdToJson(this);

  static Cipd fromJson(Map<String, dynamic> json) => _$CipdFromJson(json);
}

@JsonSerializable(includeIfNull: false)
class Source extends JsonBody {
  const Source({this.cipd});

  final Cipd? cipd;

  @override
  Map<String, dynamic> toJson() => _$SourceToJson(this);

  static Source fromJson(Map<String, dynamic> json) => _$SourceFromJson(json);
}

// BuildInfra/Buildbucket/Agent/Input
@JsonSerializable(includeIfNull: false)
class Cas extends JsonBody {
  const Cas({
    this.casInstance,
    this.digest,
  });

  final String? casInstance;
  final Digest? digest;

  @override
  Map<String, dynamic> toJson() => _$CasToJson(this);

  static Cas fromJson(Map<String, dynamic> json) => _$CasFromJson(json);
}

@JsonSerializable(includeIfNull: false)
class Digest extends JsonBody {
  const Digest({
    this.hash,
    this.sizeBytes,
  });

  final String? hash;
  final int? sizeBytes;

  @override
  Map<String, dynamic> toJson() => _$DigestToJson(this);

  static Digest fromJson(Map<String, dynamic> json) => _$DigestFromJson(json);
}

@JsonSerializable(includeIfNull: false)
class InputDataRefPackageSpec extends JsonBody {
  const InputDataRefPackageSpec({
    this.package,
    this.version,
  });

  final String? package;
  final String? version;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

@JsonSerializable(includeIfNull: false)
class InputDataRefCipd extends JsonBody {
  const InputDataRefCipd({
    this.server,
    this.specs,
  });

  final String? server;
  final List<InputDataRefPackageSpec>? specs;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

@JsonSerializable(includeIfNull: false)
class InputDataRef extends JsonBody {
  const InputDataRef({
    this.cas,
    this.cipd,
    this.onPath,
  });

  final Cas? cas;
  final InputDataRefCipd? cipd;
  final List<String>? onPath;

  @override
  Map<String, dynamic> toJson() => _$InputDataRefToJson(this);
}

// BuildInfra/Buildbucket/Agent/Output
@JsonSerializable(includeIfNull: false)
class ResolvedDataRefTiming extends JsonBody {
  const ResolvedDataRefTiming({
    this.fetchDuration,
    this.installDuration,
  });

  final Duration? fetchDuration;
  final Duration? installDuration;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

@JsonSerializable(includeIfNull: false)
class ResolvedDataRefCipd extends JsonBody {
  const ResolvedDataRefCipd({this.specs});

  final List<ResolvedDataRefPackageSpec>? specs;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

@JsonSerializable(includeIfNull: false)
class ResolvedDataRefCas extends JsonBody {
  const ResolvedDataRefCas({this.timing});

  final ResolvedDataRefTiming? timing;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

@JsonSerializable(includeIfNull: false)
class ResolvedDataRefPackageSpec extends JsonBody {
  const ResolvedDataRefPackageSpec({
    this.skipped,
    this.package,
    this.version,
    this.wasCached,
    this.timing,
  });

  final bool? skipped;
  final String? package;
  final String? version;
  final build_bucket.Trinary? wasCached;
  final ResolvedDataRefTiming? timing;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

@JsonSerializable(includeIfNull: false)
class ResolvedDataRef extends JsonBody {
  const ResolvedDataRef({
    this.cipd,
    this.cas,
  });

  final ResolvedDataRefCipd? cipd;
  final ResolvedDataRefCas? cas;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

@JsonSerializable(includeIfNull: false)
class AgentInput extends JsonBody {
  const AgentInput(this.data);

  final Map<String, InputDataRef>? data;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

@JsonSerializable(includeIfNull: false)
class AgentOutput extends JsonBody {
  const AgentOutput({
    this.resolvedData,
    this.status,
    this.summaryHtml,
    this.agentPlatform,
    this.totalDuration,
  });

  final Map<String, ResolvedDataRef>? resolvedData;
  final build_bucket.Status? status;
  final String? summaryHtml;
  final String? agentPlatform;
  final Duration? totalDuration;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

enum Purpose {
  @JsonValue('PURPOSE_UNSPECIFIED')
  purposeUnspecified,
  @JsonValue('PURPOSE_EXE_PAYLOAD')
  purposeExePayload,
  @JsonValue('PURPOSE_BBAGENT_UTILITY')
  purposeBbAgentUtility,
}

@JsonSerializable(includeIfNull: false)
class Agent extends JsonBody {
  const Agent({
    this.input,
    this.output,
    this.source,
    this.purposes,
  });

  final AgentInput? input;
  final AgentOutput? output;
  final Source? source;
  final Map<String, Purpose>? purposes;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

enum ExperimentReason {
  @JsonValue('EXPERIMENT_REASON_UNSET')
  experimentReasonUnset,
  @JsonValue('EXPERIMENT_REASON_GLOBAL_DEFAULT')
  experimentReasonGlobalDefault,
  @JsonValue('EXPERIMENT_REASON_BUILDER_CONFIG')
  experimentReasonBuilderConfig,
  @JsonValue('EXPERIMENT_REASON_GLOBAL_MINIMUM')
  experimentReasonGlobalMinimum,
  @JsonValue('EXPERIMENT_REASON_REQUESTED')
  experimentReasonRequested,
  @JsonValue('EXPERIMENT_REASON_GLOBAL_INACTIVE')
  experimentReasonGlobalInactive,
}

@JsonSerializable(includeIfNull: false)
class BuildBucket extends JsonBody {
  const BuildBucket({
    this.serviceConfigRevision,
    this.requestedProperties,
    this.requestedDimensions,
    this.hostname,
    this.experimentReasons,
    this.agentExecutable,
    this.agent,
    this.knownPublicGerritHosts,
    this.buildNumber,
  });
  final String? serviceConfigRevision;
  final Map<String, Object>? requestedProperties;
  final List<build_bucket.RequestedDimension>? requestedDimensions;
  final String? hostname;
  final Map<String, ExperimentReason>? experimentReasons;
  final Map<String, ResolvedDataRef>? agentExecutable;
  final Agent? agent;
  final List<String>? knownPublicGerritHosts;
  final bool? buildNumber;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

@JsonSerializable(includeIfNull: false)
class CacheEntry extends JsonBody {
  const CacheEntry({
    this.name,
    this.path,
    this.waitForWarmCache,
    this.envVar,
  });
  final String? name;
  final String? path;
  final Duration? waitForWarmCache;
  final String? envVar;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

@JsonSerializable(includeIfNull: false)
class Swarming extends JsonBody {
  const Swarming({
    this.hostname,
    this.taskId,
    this.parentRunId,
    this.taskServiceAccount,
    this.priority,
    this.taskDimensions,
    this.botDimensions,
    this.caches,
  });
  final String? hostname;
  final String? taskId;
  final String? parentRunId;
  final String? taskServiceAccount;
  final int? priority;
  final List<build_bucket.RequestedDimension>? taskDimensions;
  final List<build_bucket.StringPair>? botDimensions;
  final List<CacheEntry>? caches;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

@JsonSerializable(includeIfNull: false)
class Recipe extends JsonBody {
  const Recipe({
    this.cipdPackage,
    this.name,
  });
  final String? cipdPackage;
  final String? name;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

@JsonSerializable(includeIfNull: false)
class InputCipdPackage extends JsonBody {
  const InputCipdPackage({
    this.name,
    this.version,
    this.server,
    this.path,
  });
  final String? name;
  final String? version;
  final String? server;
  final String? path;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

@JsonSerializable(includeIfNull: false)
class BBAgentInput extends JsonBody {
  const BBAgentInput({this.cipdPackages});

  final List<InputCipdPackage>? cipdPackages;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

@JsonSerializable(includeIfNull: false)
class BBAgent extends JsonBody {
  const BBAgent({
    this.payloadPath,
    this.cacheDir,
    this.knownPublicGerritHosts,
    this.input,
  });
  final String? payloadPath;
  final String? cacheDir;
  final List<String>? knownPublicGerritHosts;
  final BBAgentInput? input;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

@JsonSerializable(includeIfNull: false)
class Backend extends JsonBody {
  const Backend({
    this.config,
    this.task,
    this.caches,
    this.taskDimensions,
  });
  final Map<String, Object>? config;
  final build_bucket.Task? task;
  final List<CacheEntry>? caches;
  final List<build_bucket.RequestedDimension>? taskDimensions;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

@JsonSerializable(includeIfNull: false)
class BuildInfra extends JsonBody {
  const BuildInfra({
    this.buildBucket,
    this.swarming,
    this.recipe,
    this.bbAgent,
    this.backend,
  });
  final BuildBucket? buildBucket;
  final Swarming? swarming;
  final Recipe? recipe;
  final BBAgent? bbAgent;
  final Backend? backend;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
