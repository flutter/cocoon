// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus;

import '../logic/qualified_task.dart';
import '../widgets/filter_property_sheet.dart';

/// A filter object for controlling which entries are visible in the Build dashboard grid
/// of tasks. This filter object can filter on a number of properties of the tasks including
/// the name of the task, information on the commit that generated the tasks, and platform
/// stage type toggles.
@immutable
class TaskGridFilter extends FilterPropertySource {
  TaskGridFilter({
    RegExp taskFilter,
    RegExp authorFilter,
    RegExp messageFilter,
    RegExp hashFilter,
    this.showAndroid,
    this.showIos,
    this.showWindows,
    this.showCirrus,
    this.showLuci,
  })  : taskFilter = _checkRegExp(taskFilter),
        authorFilter = _checkRegExp(authorFilter),
        messageFilter = _checkRegExp(messageFilter),
        hashFilter = _checkRegExp(hashFilter);

  factory TaskGridFilter.fromMap(Map<String, String> valueMap) => defaultFilter.copyWithMap(valueMap);

  /// The default [TaskGridFilter] object representing a filter that approves all tasks for display.
  static final TaskGridFilter defaultFilter = TaskGridFilter(
    taskFilter: null,
    authorFilter: null,
    messageFilter: null,
    hashFilter: null,
    showAndroid: true,
    showIos: true,
    showWindows: true,
    showCirrus: true,
    showLuci: true,
  );

  static RegExp _regExpFromString(String filterString) {
    return (filterString == null) ? null : RegExp(filterString);
  }

  static RegExp _checkRegExp(RegExp filter) {
    if (filter == null || filter.pattern == '') {
      return null;
    }
    return filter;
  }

  static bool _boolFromString(String value) {
    if (value == 'true' || value == 't') {
      return true;
    }
    if (value == 'false' || value == 'f') {
      return false;
    }
    return null;
  }

  /// A utility method for making a copy of the filter with only some values changed.
  /// Only non-null named parameters will modify the associated filter property.
  ///
  /// Note that to reset the [RegExp] properties to null, you can pass in a regular
  /// expression whose pattern is empty. Such a pattern matches all Strings anyway
  /// and will be replaced with a null value by the copying constructor.
  TaskGridFilter copyWith({
    RegExp taskFilter,
    RegExp authorFilter,
    RegExp messageFilter,
    RegExp hashFilter,
    bool showAndroid,
    bool showIos,
    bool showWindows,
    bool showCirrus,
    bool showLuci,
  }) =>
      TaskGridFilter(
        taskFilter: taskFilter ?? this.taskFilter,
        authorFilter: authorFilter ?? this.authorFilter,
        messageFilter: messageFilter ?? this.messageFilter,
        hashFilter: hashFilter ?? this.hashFilter,
        showAndroid: showAndroid ?? this.showAndroid,
        showIos: showIos ?? this.showIos,
        showWindows: showWindows ?? this.showWindows,
        showCirrus: showCirrus ?? this.showCirrus,
        showLuci: showLuci ?? this.showLuci,
      );

  /// A utility method for making a copy of the filter with only some values changed
  /// as specified by a [Map]. Values in the map must be strings, but appropriate
  /// conversions to the actual value type of the property will be performed on
  /// the strings in the standard way for the property type.
  @override
  TaskGridFilter copyWithMap(Map<String, String> valueMap) {
    if (valueMap == null) {
      return this;
    }
    return copyWith(
      taskFilter: _regExpFromString(valueMap[taskFilterKey]),
      authorFilter: _regExpFromString(valueMap[authorFilterKey]),
      messageFilter: _regExpFromString(valueMap[messageFilterKey]),
      hashFilter: _regExpFromString(valueMap[hashFilterKey]),
      showAndroid: _boolFromString(valueMap[showAndroidKey]),
      showIos: _boolFromString(valueMap[showIosKey]),
      showWindows: _boolFromString(valueMap[showWindowsKey]),
      showCirrus: _boolFromString(valueMap[showCirrusKey]),
      showLuci: _boolFromString(valueMap[showLuciKey]),
    );
  }

  /// The name of the key used to initialize or modify the [taskFilter] property.
  static const String taskFilterKey = 'taskFilter';

  /// The name of the key used to initialize or modify the [authorFilter] property.
  static const String authorFilterKey = 'authorFilter';

  /// The name of the key used to initialize or modify the [messageFilter] property.
  static const String messageFilterKey = 'messageFilter';

  /// The name of the key used to initialize or modify the [hashFilter] property.
  static const String hashFilterKey = 'hashFilter';

  /// The name of the key used to initialize or modify the [showAndroid] property.
  static const String showAndroidKey = 'showAndroid';

  /// The name of the key used to initialize or modify the [showIos] property.
  static const String showIosKey = 'showIos';

  /// The name of the key used to initialize or modify the [showWindows] property.
  static const String showWindowsKey = 'showWindows';

  /// The name of the key used to initialize or modify the [showCirrus] property.
  static const String showCirrusKey = 'showCirrus';

  /// The name of the key used to initialize or modify the [showLuci] property.
  static const String showLuciKey = 'showLuci';

  /// The [taskFilter] property is a regular expression that must match the name of the
  /// task in the grid. This property will filter out columns on the build dashboard.
  final RegExp taskFilter;

  /// The [authorFilter] property is a regular expression that must match the name of the
  /// author of the task's commit. This property will filter out rows on the build dashboard.
  final RegExp authorFilter;

  /// The [messageFilter] property is a regular expression that must match the commit message
  /// of the task's commit. This property will filter out rows on the build dashboard.
  final RegExp messageFilter;

  /// The [hashFilter] property is a regular expression that must match the hash of the
  /// task's commit. This property will filter out rows on the build dashboard.
  final RegExp hashFilter;

  /// The [showAndroid] property is a boolean that indicates whether to display tasks produced
  /// by an Android stage in the devicelab.
  /// This property will filter out columns on the build dashboard.
  final bool showAndroid;

  /// The [showIos] property is a boolean that indicates whether to display tasks produced
  /// by an iOS stage in the devicelab.
  /// This property will filter out columns on the build dashboard.
  final bool showIos;

  /// The [showWindows] property is a boolean that indicates whether to display tasks produced
  /// by a Windows stage in the devicelab.
  /// This property will filter out columns on the build dashboard.
  final bool showWindows;

  /// The [showCirrus] property is a boolean that indicates whether to display tasks produced
  /// by the Cirrus stage in the devicelab.
  /// This property will filter out columns on the build dashboard.
  final bool showCirrus;

  /// The [showLuci] property is a boolean that indicates whether to display tasks produced
  /// by a Luci stage in the devicelab.
  /// This property will filter out columns on the build dashboard.
  final bool showLuci;

  /// Check the values in the [CommitStatus] for compatibility with the properties of this
  /// filter and return [true] iff the commit row should be displayed.
  bool matchesCommit(CommitStatus commitStatus) {
    if (authorFilter != null && !authorFilter.hasMatch(commitStatus.commit.author)) {
      return false;
    }
    if (messageFilter != null && !messageFilter.hasMatch(commitStatus.commit.message)) {
      return false;
    }
    if (hashFilter != null && !hashFilter.hasMatch(commitStatus.commit.sha)) {
      return false;
    }
    return true;
  }

  /// Check the values in the [QualifiedTask] for compatibility with the properties of this
  /// filter and return [true] iff the commit column should be displayed.
  bool matchesTask(QualifiedTask qualifiedTask) {
    if (taskFilter != null && !taskFilter.hasMatch(qualifiedTask.task)) {
      return false;
    }
    bool stageFlag;
    switch (qualifiedTask.stage) {
      case StageName.devicelab:
        stageFlag = showAndroid;
        break;
      case StageName.devicelabIOs:
        stageFlag = showIos;
        break;
      case StageName.devicelabWin:
        stageFlag = showWindows;
        break;
      case StageName.cirrus:
        stageFlag = showCirrus;
        break;
      case StageName.luci:
        stageFlag = showLuci;
        break;
      default:
        return false;
    }
    return stageFlag;
  }

  /// Convert the filter into a String map that can be used to reconstruct the filter
  /// using the [fromMap] constructor and/or injecting its data into a JSON or URL query
  /// parameter list.
  Map<String, String> toMap() => <String, String>{
        if (taskFilter != defaultFilter.taskFilter) taskFilterKey: taskFilter.pattern,
        if (authorFilter != defaultFilter.authorFilter) authorFilterKey: authorFilter.pattern,
        if (messageFilter != defaultFilter.messageFilter) messageFilterKey: messageFilter.pattern,
        if (hashFilter != defaultFilter.hashFilter) hashFilterKey: hashFilter.pattern,
        if (showAndroid != defaultFilter.showAndroid) showAndroidKey: showAndroid.toString(),
        if (showIos != defaultFilter.showIos) showIosKey: showIos.toString(),
        if (showWindows != defaultFilter.showWindows) showWindowsKey: showWindows.toString(),
        if (showCirrus != defaultFilter.showCirrus) showCirrusKey: showCirrus.toString(),
        if (showLuci != defaultFilter.showLuci) showLuciKey: showLuci.toString(),
      };

  /// Return the String representation of the indicated field, regardless of the field's
  /// natural type.
  @override
  String getString(String fieldName) {
    switch (fieldName) {
      case taskFilterKey:
        return taskFilter?.pattern;
      case authorFilterKey:
        return authorFilter?.pattern;
      case messageFilterKey:
        return messageFilter?.pattern;
      case hashFilterKey:
        return hashFilter?.pattern;
      case showAndroidKey:
        return showAndroid.toString();
      case showIosKey:
        return showIos.toString();
      case showWindowsKey:
        return showWindows.toString();
      case showCirrusKey:
        return showCirrus.toString();
      case showLuciKey:
        return showLuci.toString();
    }
    throw 'unrecognized field name in getString($fieldName)';
  }

  /// Return the bool representing the indicated field, the natural type of the field
  /// must be a boolean.
  @override
  bool getBool(String fieldName) {
    switch (fieldName) {
      case taskFilterKey:
      case authorFilterKey:
      case messageFilterKey:
      case hashFilterKey:
        throw 'attempting to get a bool value for a regular expression property';
      case showAndroidKey:
        return showAndroid;
      case showIosKey:
        return showIos;
      case showWindowsKey:
        return showWindows;
      case showCirrusKey:
        return showCirrus;
      case showLuciKey:
        return showLuci;
    }
    throw 'unrecognized field name in getString($fieldName)';
  }

  static const List<FilterProperty> _properties = <FilterProperty>[
    RegExpFilterProperty(fieldName: taskFilterKey, label: 'Task Name'),
    RegExpFilterProperty(fieldName: authorFilterKey, label: 'Commit Author'),
    RegExpFilterProperty(fieldName: messageFilterKey, label: 'Commit Message'),
    RegExpFilterProperty(fieldName: hashFilterKey, label: 'Commit Hash'),
    BoolFilterPropertyGroup(
      label: 'Stages',
      members: <BoolFilterProperty>[
        BoolFilterProperty(fieldName: showAndroidKey, label: 'Android'),
        BoolFilterProperty(fieldName: showIosKey, label: 'iOS'),
        BoolFilterProperty(fieldName: showWindowsKey, label: 'Windows'),
        BoolFilterProperty(fieldName: showCirrusKey, label: 'Cirrus'),
        BoolFilterProperty(fieldName: showLuciKey, label: 'Luci'),
      ],
    ),
  ];

  /// Return the list of properties of this filter in a form that can be used by a
  /// [FilterPropertySheet] to display the fields to a user and allow them to edit the values.
  @override
  List<FilterProperty> get properties => _properties;

  String _stringFor(String label, Object value) => value == null ? '' : '$label: $value,';

  @override
  String toString() {
    return 'TaskGridFilter('
        '${_stringFor(taskFilterKey, taskFilter?.pattern)}'
        '${_stringFor(authorFilterKey, authorFilter?.pattern)}'
        '${_stringFor(messageFilterKey, messageFilter?.pattern)}'
        '${_stringFor(hashFilterKey, hashFilter?.pattern)}'
        '${_stringFor(showAndroidKey, showAndroid)}'
        '${_stringFor(showIosKey, showIos)}'
        '${_stringFor(showWindowsKey, showWindows)}'
        '${_stringFor(showCirrusKey, showCirrus)}'
        '${_stringFor(showLuciKey, showLuci)}'
        ')';
  }

  @override
  int get hashCode {
    return hashValues(
      taskFilter,
      authorFilter,
      messageFilter,
      hashFilter,
      showAndroid,
      showIos,
      showWindows,
      showCirrus,
      showLuci,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is TaskGridFilter &&
        taskFilter == other.taskFilter &&
        authorFilter == other.authorFilter &&
        messageFilter == other.messageFilter &&
        hashFilter == other.hashFilter &&
        showAndroid == other.showAndroid &&
        showIos == other.showIos &&
        showWindows == other.showWindows &&
        showCirrus == other.showCirrus &&
        showLuci == other.showLuci;
  }
}
