// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'entity.dart';

/// Datastore key.
class Key {
  static const _serializer = const _KeySerializer();

  const Key(this.value);

  final String value;

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Key other) => other != null && other.value == value;
}

class _KeySerializer implements JsonSerializer<Key> {
  const _KeySerializer();

  @override
  Key deserialize(dynamic jsonValue) {
    return new Key(jsonValue);
  }

  @override
  dynamic serialize(Key key) {
    return key.value;
  }
}

class GetStatusResult extends Entity {
  static final _serializer = new EntitySerializer(
    (Map<String, dynamic> props) => new GetStatusResult(props),
    <String, JsonSerializer>{
      'Statuses': listOf(BuildStatus._serializer),
      'AgentStatuses': listOf(AgentStatus._serializer),
    }
  );

  GetStatusResult([Map<String, dynamic> props]) : super(_serializer, props);

  static GetStatusResult fromJson(dynamic json) =>
      _serializer.deserialize(json);

  List<BuildStatus> get statuses => this['Statuses'];
  List<AgentStatus> get agentStatuses => this['AgentStatuses'];
}

class BuildStatus extends Entity {
  static final _serializer = new EntitySerializer(
    (Map<String, dynamic> props) => new BuildStatus(props),
    <String, JsonSerializer>{
      'Checklist': ChecklistEntity._serializer,
      'Stages': listOf(Stage._serializer),
    }
  );

  BuildStatus([Map<String, dynamic> props]) : super(_serializer, props);

  ChecklistEntity get checklist => this['Checklist'];
  List<Stage> get stages => this['Stages'];
}

class AgentStatus extends Entity {
  static final _serializer = new EntitySerializer(
    (Map<String, dynamic> props) => new AgentStatus(props),
    <String, JsonSerializer>{
    	'AgentID': string(),
    	'IsHealthy': boolean(),
    	'HealthCheckTimestamp': dateTime(),
    	'HealthDetails': string(),
    }
  );

  AgentStatus([Map<String, dynamic> props]) : super(_serializer, props);

  String get agentId => this['AgentID'];
  bool get isHealthy => this['IsHealthy'];
  DateTime get healthCheckTimestamp => this['HealthCheckTimestamp'];
  String get healthDetails => this['HealthDetails'];
}

class CommitInfo extends Entity {
  static final _serializer = new EntitySerializer(
    (Map<String, dynamic> props) => new CommitInfo(props),
    <String, JsonSerializer>{
      'Sha': string(),
      'Author': AuthorInfo._serializer,
    }
  );

  CommitInfo([Map<String, dynamic> props]) : super(_serializer, props);

  String get sha => this['Sha'];
  AuthorInfo get author => this['Author'];
}

class AuthorInfo extends Entity {
  static final _serializer = new EntitySerializer(
    (Map<String, dynamic> props) => new AuthorInfo(props),
    <String, JsonSerializer>{
      'Login': string(),
      'avatar_url': string(),
    }
  );

  AuthorInfo([Map<String, dynamic> props]) : super(_serializer, props);

  String get login => this['Login'];
  String get avatarUrl => this['avatar_url'];
}

class ChecklistEntity extends Entity {
  static final _serializer = new EntitySerializer(
    (Map<String, dynamic> props) => new ChecklistEntity(props),
    <String, JsonSerializer>{
      'Key': Key._serializer,
      'Checklist': Checklist._serializer,
    }
  );

  ChecklistEntity([Map<String, dynamic> props]) : super(_serializer, props);

  Key get key => this['Key'];
  Checklist get checklist => this['Checklist'];
}

class Checklist extends Entity {
  static final _serializer = new EntitySerializer(
    (Map<String, dynamic> props) => new Checklist(props),
    <String, JsonSerializer>{
      'FlutterRepositoryPath': string(),
      'Commit': CommitInfo._serializer,
      'CreateTimestamp': dateTime(),
    }
  );

  Checklist([Map<String, dynamic> props]) : super(_serializer, props);

  String get flutterRepositoryPath => this['FlutterRepositoryPath'];
  CommitInfo get commit => this['Commit'];
  DateTime get createTimestamp => this['CreateTimestamp'];
}

class Stage extends Entity {
  static final _serializer = new EntitySerializer(
    (Map<String, dynamic> props) => new Stage(props),
    <String, JsonSerializer>{
      'Name': string(),
      'Tasks': listOf(TaskEntity._serializer),
    }
  );

  Stage([Map<String, dynamic> props]) : super(_serializer, props);

  String get name => this['Name'];
  List<TaskEntity> get tasks => this['Tasks'];
}

class TaskEntity extends Entity {
  static final _serializer = new EntitySerializer(
    (Map<String, dynamic> props) => new TaskEntity(props),
    <String, JsonSerializer>{
      'Key': Key._serializer,
      'Task': Task._serializer,
    }
  );

  TaskEntity([Map<String, dynamic> props]) : super(_serializer, props);

  Key get key => this['Key'];
  Task get task => this['Task'];
}

class Task extends Entity {
  static final _serializer = new EntitySerializer(
    (Map<String, dynamic> props) => new Task(props),
    <String, JsonSerializer>{
      'ChecklistKey': Key._serializer,
      'StageName': string(),
      'Name': string(),
      'Status': string(),
      'StartTimestamp': dateTime(),
      'EndTimestamp': dateTime(),
      'Attempts': number(),
    }
  );

  Task([Map<String, dynamic> props]) : super(_serializer, props);

  Key get checklistKey => this['ChecklistKey'];
  String get stageName => this['StageName'];
  String get name => this['Name'];
  String get status => this['Status'];
  DateTime get startTimestamp => this['StartTimestamp'];
  DateTime get endTimestamp => this['EndTimestamp'];
  int get attempts => this['Attempts'];
}

class GetBenchmarksResult extends Entity {
  static final _serializer = new EntitySerializer(
    (Map<String, dynamic> props) => new GetBenchmarksResult(props),
    <String, JsonSerializer>{
      'Benchmarks': listOf(BenchmarkData._serializer),
    }
  );

  GetBenchmarksResult([Map<String, dynamic> props]) : super(_serializer, props);

  static GetBenchmarksResult fromJson(dynamic json) =>
      _serializer.deserialize(json);

  List<BenchmarkData> get benchmarks => this['Benchmarks'];
}

class BenchmarkData extends Entity {
  static final _serializer = new EntitySerializer(
    (Map<String, dynamic> props) => new BenchmarkData(props),
    <String, JsonSerializer>{
      'Timeseries': TimeseriesEntity._serializer,
    	'Values': listOf(TimeseriesValue._serializer),
    }
  );

  BenchmarkData([Map<String, dynamic> props]) : super(_serializer, props);

  TimeseriesEntity get timeseries => this['Timeseries'];
  List<TimeseriesValue> get values => this['Values'];
}

class TimeseriesEntity extends Entity {
  static final _serializer = new EntitySerializer(
    (Map<String, dynamic> props) => new TimeseriesEntity(props),
    <String, JsonSerializer>{
      'Key': Key._serializer,
      'Timeseries': Timeseries._serializer,
    }
  );

  TimeseriesEntity([Map<String, dynamic> props]) : super(_serializer, props);

  Key get key => this['Key'];
  Timeseries get timeseries => this['Timeseries'];
}

class Timeseries extends Entity {
  static final _serializer = new EntitySerializer(
    (Map<String, dynamic> props) => new Timeseries(props),
    <String, JsonSerializer>{
      'ID': string(),
      'Label': string(),
      'Unit': string(),
    }
  );

  Timeseries([Map<String, dynamic> props]) : super(_serializer, props);

  String get id => this['ID'];
  String get label => this['Label'];
  String get unit => this['Unit'];
}

class TimeseriesValue extends Entity {
  static final _serializer = new EntitySerializer(
    (Map<String, dynamic> props) => new TimeseriesValue(props),
    <String, JsonSerializer>{
      'CreateTimestamp': number(),
      'Revision': string(),
      'Value': number(),
    }
  );

  TimeseriesValue([Map<String, dynamic> props]) : super(_serializer, props);

  int get createTimestamp => this['CreateTimestamp'];
  String get revision => this['Revision'];
  double get value => this['Value'];
}
