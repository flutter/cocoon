import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:json_annotation/json_annotation.dart';

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
  Map<String, dynamic> toJson() => _$InputDataRefPackageSpecToJson(this);

  static InputDataRefPackageSpec fromJson(Map<String, dynamic> json) => _$InputDataRefPackageSpecFromJson(json);
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
  Map<String, dynamic> toJson() => _$InputDataRefCipdToJson(this);

  static InputDataRefCipd fromJson(Map<String, dynamic> json) => _$InputDataRefCipdFromJson(json);
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

  static InputDataRef fromJson(Map<String, dynamic> json) => _$InputDataRefFromJson(json);
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
  Map<String, dynamic> toJson() => _$ResolvedDataRefTimingToJson(this);

  static ResolvedDataRefTiming fromJson(Map<String, dynamic> json) => _$ResolvedDataRefTimingFromJson(json);
}

@JsonSerializable(includeIfNull: false)
class ResolvedDataRefCipd extends JsonBody {
  const ResolvedDataRefCipd({this.specs});

  final List<ResolvedDataRefPackageSpec>? specs;

  @override
  Map<String, dynamic> toJson() => _$ResolvedDataRefCipdToJson(this);

  static ResolvedDataRefCipd fromJson(Map<String, dynamic> json) => _$ResolvedDataRefCipdFromJson(json);
}

@JsonSerializable(includeIfNull: false)
class ResolvedDataRefCas extends JsonBody {
  const ResolvedDataRefCas({this.timing});

  final ResolvedDataRefTiming? timing;

  @override
  Map<String, dynamic> toJson() => _$ResolvedDataRefCasToJson(this);

  static ResolvedDataRefCas fromJson(Map<String, dynamic> json) => _$ResolvedDataRefCasFromJson(json);
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
  final Trinary? wasCached;
  final ResolvedDataRefTiming? timing;

  @override
  Map<String, dynamic> toJson() => _$ResolvedDataRefPackageSpecToJson(this);

  static ResolvedDataRefPackageSpec fromJson(Map<String, dynamic> json) => _$ResolvedDataRefPackageSpecFromJson(json);
}

/// This type doesn't quite map to a bool, because there are actually four states
/// when you include whether it's present or not.
enum Trinary {
  /// A true value.
  @JsonValue('YES')
  yes,

  /// A false value.
  @JsonValue('NO')
  no,

  /// An explicit null value, which may or may not be treated differently from
  /// setting the JSON field to null.
  @JsonValue('UNSET')
  unset,
}

/// Build status values.
enum Status {
  /// Should not be used.
  @JsonValue('STATUS_UNSPECIFIED')
  unspecified,

  /// The status of a scheduled or pending build.
  @JsonValue('SCHEDULED')
  scheduled,

  /// The status of a started (running) build.
  @JsonValue('STARTED')
  started,

  /// A mask of `succes | failure | infraFailure | canceled`.
  @JsonValue('ENDED_MASK')
  ended,

  /// The build has successfully completed.
  @JsonValue('SUCCESS')
  success,

  /// The build has failed to complete some step due to a faulty test or commit.
  @JsonValue('FAILURE')
  failure,

  /// The build has failed due to an infrastructure related failure.
  @JsonValue('INFRA_FAILURE')
  infraFailure,

  /// The build was canceled.
  @JsonValue('CANCELED')
  canceled,
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
  Map<String, dynamic> toJson() => _$ResolvedDataRefToJson(this);

  static ResolvedDataRef fromJson(Map<String, dynamic> json) => _$ResolvedDataRefFromJson(json);
}

@JsonSerializable(includeIfNull: false)
class AgentInput extends JsonBody {
  const AgentInput(this.data);

  final Map<String, InputDataRef>? data;

  @override
  Map<String, dynamic> toJson() => _$AgentInputToJson(this);

  static AgentInput fromJson(Map<String, dynamic> json) => _$AgentInputFromJson(json);
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
  final Status? status;
  final String? summaryHtml;
  final String? agentPlatform;
  final Duration? totalDuration;

  @override
  Map<String, dynamic> toJson() => _$AgentOutputToJson(this);

  static AgentOutput fromJson(Map<String, dynamic> json) => _$AgentOutputFromJson(json);
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
  Map<String, dynamic> toJson() => _$AgentToJson(this);

  static Agent fromJson(Map<String, dynamic> json) => _$AgentFromJson(json);
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
  final List<RequestedDimension>? requestedDimensions;
  final String? hostname;
  final Map<String, ExperimentReason>? experimentReasons;
  final Map<String, ResolvedDataRef>? agentExecutable;
  final Agent? agent;
  final List<String>? knownPublicGerritHosts;
  final bool? buildNumber;

  @override
  Map<String, dynamic> toJson() => _$BuildBucketToJson(this);

  static BuildBucket fromJson(Map<String, dynamic> json) => _$BuildBucketFromJson(json);
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
  final String? waitForWarmCache;
  final String? envVar;

  @override
  Map<String, dynamic> toJson() => _$CacheEntryToJson(this);

  static CacheEntry fromJson(Map<String, dynamic> json) => _$CacheEntryFromJson(json);
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
  final List<RequestedDimension>? taskDimensions;
  final List<StringPair>? botDimensions;
  final List<CacheEntry>? caches;

  @override
  Map<String, dynamic> toJson() => _$SwarmingToJson(this);

  static Swarming fromJson(Map<String, dynamic> json) => _$SwarmingFromJson(json);
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
  Map<String, dynamic> toJson() => _$RecipeToJson(this);

  static Recipe fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
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
  Map<String, dynamic> toJson() => _$InputCipdPackageToJson(this);

  static InputCipdPackage fromJson(Map<String, dynamic> json) => _$InputCipdPackageFromJson(json);
}

@JsonSerializable(includeIfNull: false)
class BBAgentInput extends JsonBody {
  const BBAgentInput({this.cipdPackages});

  final List<InputCipdPackage>? cipdPackages;

  @override
  Map<String, dynamic> toJson() => _$BBAgentInputToJson(this);

  static BBAgentInput fromJson(Map<String, dynamic> json) => _$BBAgentInputFromJson(json);
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
  Map<String, dynamic> toJson() => _$BBAgentToJson(this);

  static BBAgent fromJson(Map<String, dynamic> json) => _$BBAgentFromJson(json);
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
  final BuildBucketTask? task;
  final List<CacheEntry>? caches;
  final List<RequestedDimension>? taskDimensions;

  @override
  Map<String, dynamic> toJson() => _$BackendToJson(this);

  static Backend fromJson(Map<String, dynamic> json) => _$BackendFromJson(json);
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
  Map<String, dynamic> toJson() =>_$BuildInfraToJson(this);

  static BuildInfra fromJson(Map<String, dynamic> json) => _$BuildInfraFromJson(json);
}

/// A requested dimension. Looks like StringPair, but also has an expiration.
@JsonSerializable(includeIfNull: false)
class RequestedDimension extends JsonBody {
  const RequestedDimension({
    required this.key,
    this.value,
    this.expiration,
  });

  static RequestedDimension fromJson(Map<String, dynamic> json) => _$RequestedDimensionFromJson(json);

  final String? key;
  final String? value;

  /// If set, ignore this dimension after this duration. Must be a multiple of 1 minute. The format is '<seconds>s',
  /// e.g. '120s' represents 120 seconds.
  final String? expiration;

  @override
  Map<String, dynamic> toJson() => _$RequestedDimensionToJson(this);
}

@JsonSerializable(includeIfNull: false)
class StringPair extends JsonBody {
  const StringPair({
    this.key,
    this.value,
  });
  final String? key;
  final String? value;

  @override
  Map<String, dynamic> toJson() => _$StringPairToJson(this);

  static StringPair fromJson(Map<String, dynamic> json) => _$StringPairFromJson(json);
}

@JsonSerializable(includeIfNull: false)
class TaskId extends JsonBody {
  const TaskId({this.target, this.id});
  final String? target;
  final String? id;

  @override
  Map<String, dynamic> toJson() => _$TaskIdToJson(this);

  static TaskId fromJson(Map<String, dynamic> json) => _$TaskIdFromJson(json);
}

@JsonSerializable(includeIfNull: false)
class BuildBucketTask extends JsonBody {
  const BuildBucketTask({
    this.taskId,
    this.link,
    this.status,
    this.summaryHtml,
    this.updateId,
    this.details,
  });
  final TaskId? taskId;
  final String? link;
  final Status? status;
  final String? summaryHtml;
  final int? updateId;
  final Map<String, Object>? details;

  @override
  Map<String, dynamic> toJson() => _$BuildBucketTaskToJson(this);

  static BuildBucketTask fromJson(Map<String, dynamic> json) => _$BuildBucketTaskFromJson(json);
}