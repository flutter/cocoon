// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:googleapis/datastore/v1.dart';

import 'entities.dart';

/// A [Codec] for the [Timeseries] and [TimeseriesEntity] objects.
const Codec<TimeseriesEntity, Entity> timeseriesCodec =
    const _TimeseriesEntityCodec();

/// A [Codec] for the [Task] and [TaskEntity] objects.
const Codec<TaskEntity, Entity> taskCodec = const _TaskEntityCodec();

class _TimeseriesEntityCodec extends Codec<TimeseriesEntity, Entity> {
  const _TimeseriesEntityCodec();

  @override
  Converter<Entity, TimeseriesEntity> get decoder =>
      const _TimeseriesEntityDecoder();

  @override
  Converter<TimeseriesEntity, Entity> get encoder =>
      const _TimeseriesEntityEncoder();
}

const String _idField = 'ID';
const String _taskNameField = 'TaskName';
const String _labelField = 'Label';
const String _unitField = 'Unit';
const String _goalField = 'Goal';
const String _baselineField = 'Baseline';
const String _archivedField = 'Archived';

class _TimeseriesEntityDecoder extends Converter<Entity, TimeseriesEntity> {
  const _TimeseriesEntityDecoder();

  @override
  TimeseriesEntity convert(Entity input) {
    final Key key = input.key;
    return TimeseriesEntity(
        key,
        Timeseries(
            input.properties[_idField].stringValue,
            input.properties[_taskNameField].stringValue,
            input.properties[_labelField].stringValue,
            input.properties[_unitField].stringValue,
            input.properties[_goalField].doubleValue,
            input.properties[_baselineField].doubleValue,
            input.properties[_archivedField].booleanValue));
  }
}

class _TimeseriesEntityEncoder extends Converter<TimeseriesEntity, Entity> {
  const _TimeseriesEntityEncoder();

  @override
  Entity convert(TimeseriesEntity input) {
    final Entity entity = Entity();
    entity.key = input.key;
    entity.properties = <String, Value>{
      _idField: Value()..stringValue = input.timeseries.id,
      _archivedField: Value()..booleanValue = input.timeseries.archived,
      _baselineField: Value()..doubleValue = input.timeseries.baseline,
      _goalField: Value()..doubleValue = input.timeseries.goal,
      _labelField: Value()..stringValue = input.timeseries.label,
      _taskNameField: Value()..stringValue = input.timeseries.taskName,
      _unitField: Value()..stringValue = input.timeseries.unit,
    };
    return entity;
  }
}

class _TaskEntityCodec extends Codec<TaskEntity, Entity> {
  const _TaskEntityCodec();

  @override
  Converter<Entity, TaskEntity> get decoder => const _TaskEntityDecoder();

  @override
  Converter<TaskEntity, Entity> get encoder => const _TaskEntityEncoder();
}

const String _checklistKeyField = 'ChecklistKey';
const String _stageNameField = 'StageName';
const String _nameField = 'Name';
const String _requiredCapabilitiesField = 'RequiredCapabilities';
const String _statusField = 'Status';
const String _reasonField = 'Reason';
const String _reservedForAgentField = 'ReservedForAgentID';
const String _createTimestampField = 'CreateTimestamp';
const String _startTimestampField = 'StartTimestamp';
const String _endTimestampField = 'EndTimestamp';
const String _flakyField = 'Flaky';
const String _timeoutInMinutesField = 'TimeoutInMinutes';
const String _attemptsField = 'Attempts';

class _TaskEntityEncoder extends Converter<TaskEntity, Entity> {
  const _TaskEntityEncoder();

  @override
  Entity convert(TaskEntity input) {
    final Entity entity = Entity();
    final Task task = input.task;
    entity.key = input.key;
    entity.properties = <String, Value>{
      _checklistKeyField: Value()..keyValue = task.checklistKey,
      _stageNameField: Value()..stringValue = task.stageName,
      _nameField: Value()..stringValue = task.name,
      _requiredCapabilitiesField: Value()
        ..arrayValue = (ArrayValue()
          ..values = task.requiredCapabilities
              .map((String capability) => Value()..stringValue = capability)),
      _statusField: Value()..stringValue = task.status.toString(),
      _reasonField: Value()..stringValue = task.reason,
      _reservedForAgentField: Value()..stringValue = task.reservedForAgentId,
      _createTimestampField: Value()
        ..integerValue = task.createTimestamp.millisecondsSinceEpoch.toString(),
      _startTimestampField: Value()
        ..integerValue = task.startTimestamp.millisecondsSinceEpoch.toString(),
      _endTimestampField: Value()
        ..integerValue = task.endTimestamp.millisecondsSinceEpoch.toString(),
      _flakyField: Value()..booleanValue = task.flaky,
      _timeoutInMinutesField: Value()
        ..integerValue = task.timeoutInMinutes.toString(),
      _attemptsField: Value()..integerValue = task.attempts.toString(),
    };
    return entity;
  }
}

class _TaskEntityDecoder extends Converter<Entity, TaskEntity> {
  const _TaskEntityDecoder();

  @override
  TaskEntity convert(Entity input) {
    return TaskEntity(
      input.key,
      Task(
        input.properties[_checklistKeyField].keyValue,
        input.properties[_stageNameField].stringValue,
        input.properties[_nameField].stringValue,
        input.properties[_requiredCapabilitiesField].arrayValue.values
            .map((Value value) => value.stringValue)
            .toList(),
        TaskStatus(input.properties[_statusField].stringValue),
        input.properties[_reasonField].stringValue,
        int.tryParse(input.properties[_attemptsField].integerValue),
        input.properties[_reservedForAgentField].stringValue,
        DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(input.properties[_createTimestampField].integerValue)),
        DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(input.properties[_startTimestampField].integerValue)),
        DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(input.properties[_endTimestampField].integerValue)),
        input.properties[_flakyField].booleanValue,
        int.tryParse(input.properties[_timeoutInMinutesField].integerValue),
      ),
    );
  }
}

const String createTimestampField = 'CreateTimestamp';
const String dataMissingField = 'DataMissing';
const String revisionField = 'Revision';
const String taskKeyField = 'TaskKey';
const String valueField = 'Value';

class _TimeseriesValueEncoder extends Converter<TimeseriesValue, Entity> {
  const _TimeseriesValueEncoder();

  @override
  Entity convert(TimeseriesValue input) {}
}

class _TimeseriesValueDecoder extends Converter<Entity, TimeseriesValue> {
  const _TimeseriesValueDecoder();

  @override
  TimeseriesValue convert(Entity input) {
    // TODO: implement convert
  }
}
