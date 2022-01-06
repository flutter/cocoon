// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/material.dart';

import '../logic/qualified_task.dart';
import '../model/commit.pb.dart';
import '../widgets/filter_property_sheet.dart';

enum CommitFilterMode {
  /// Show only those commits that match the relevant properties in the filter.
  filter,

  /// Highlight the commits that match the relevant properties (and scroll to the
  /// first matching commit).
  highlight
}

// class CommitFilterModeProperty extends ValueFilterProperty<CommitFilterMode> {
//   CommitFilterModeProperty({CommitFilterMode value = defaultValue})
//       : _value = value,
//         super(fieldName: 'commitFilterMode', label: 'Matching Commits:');
//
//   static const CommitFilterMode defaultValue = CommitFilterMode.filter;
//
//   CommitFilterMode _value;
//
//   @override
//   String stringValue;
//
//   @override
//   bool get isDefault => _value == defaultValue;
//
//   @override
//   void reset() => _value = defaultValue;
//
//   @override
//   CommitFilterMode get value => _value;
// }

/// A filter object for controlling which entries are visible in the Build dashboard grid
/// of tasks. This filter object can filter on a number of properties of the tasks including
/// the name of the task, information on the commit that generated the tasks, and platform
/// stage type toggles.
class TaskGridFilter extends FilterPropertySource {
  TaskGridFilter();

  factory TaskGridFilter.fromMap(Map<String, String> valueMap) => TaskGridFilter()..applyMap(valueMap);

  /// True iff all of the properties of the filter are set to their default values.
  bool get isDefault =>
      _allProperties.values.toList().every((ValueFilterProperty<dynamic> element) => element.isDefault);

  /// Sets all properties of this filter to their default values.
  void reset() {
    for (final ValueFilterProperty<dynamic> property in _allProperties.values) {
      property.reset();
    }
  }

  /// Modifies this filter based on the values in the map. If the map is null, no changes are
  /// made. All keys in the [valueMap] must match one of the field names of the filter properties.
  void applyMap(Map<String, String> valueMap) {
    if (valueMap != null) {
      for (final MapEntry<String, String> mapEntry in valueMap.entries) {
        _allProperties[mapEntry.key].stringValue = mapEntry.value;
      }
    }
  }

  final RegExpFilterProperty _taskProperty = RegExpFilterProperty(fieldName: 'taskFilter', label: 'Task Name');
  final RegExpFilterProperty _authorProperty = RegExpFilterProperty(fieldName: 'authorFilter', label: 'Commit Author');
  final RegExpFilterProperty _messageProperty =
      RegExpFilterProperty(fieldName: 'messageFilter', label: 'Commit Message');
  final RegExpFilterProperty _hashProperty = RegExpFilterProperty(fieldName: 'hashFilter', label: 'Commit Hash');
  final EnumFilterProperty<CommitFilterMode> _commitFilterModeProperty =
  EnumFilterProperty<CommitFilterMode>(
    fieldName: 'commitFilterMode',
    label: 'Matching Commits',
    allValues: <CommitFilterMode>[
      CommitFilterMode.highlight,
      CommitFilterMode.filter
    ],
  );

  // [_allProperties] is a LinkedHashMap so we can trust its iteration order
  LinkedHashMap<String, ValueFilterProperty<dynamic>> _allPropertiesMap;
  LinkedHashMap<String, ValueFilterProperty<dynamic>> get _allProperties =>
      _allPropertiesMap ??= <String, ValueFilterProperty<dynamic>>{}
        ..[_taskProperty.fieldName] = _taskProperty
        ..[_authorProperty.fieldName] = _authorProperty
        ..[_messageProperty.fieldName] = _messageProperty
        ..[_hashProperty.fieldName] = _hashProperty
        ..[_commitFilterModeProperty.fieldName] = _commitFilterModeProperty;

  List<ValueFilterProperty<dynamic>> _allCommitPropertiesList;
  List<ValueFilterProperty<dynamic>> get _allCommitProperties =>
      _allCommitPropertiesList ??= <ValueFilterProperty<dynamic>>[
        _authorProperty, _messageProperty, _hashProperty,
      ];

  /// The [taskFilter] property is a regular expression that must match the name of the
  /// task in the grid. This property will filter out columns on the build dashboard.
  RegExp get taskFilter => _taskProperty.regExp;
  set taskFilter(RegExp regExp) => _taskProperty.regExp = regExp;

  /// The [authorFilter] property is a regular expression that must match the name of the
  /// author of the task's commit. This property will filter out rows on the build dashboard.
  RegExp get authorFilter => _authorProperty.regExp;
  set authorFilter(RegExp regExp) => _authorProperty.regExp = regExp;

  /// The [messageFilter] property is a regular expression that must match the commit message
  /// of the task's commit. This property will filter out rows on the build dashboard.
  RegExp get messageFilter => _messageProperty.regExp;
  set messageFilter(RegExp regExp) => _messageProperty.regExp = regExp;

  /// The [hashFilter] property is a regular expression that must match the hash of the
  /// task's commit. This property will filter out rows on the build dashboard.
  RegExp get hashFilter => _hashProperty.regExp;
  set hashFilter(RegExp regExp) => _hashProperty.regExp = regExp;

  /// The [commitFilterMode] property indicates how to handle the commits that match the
  /// commit filter properties above. See [CommitFilterMode].
  CommitFilterMode get commitFilterMode => _commitFilterModeProperty.value;
  set commitFilterMode(CommitFilterMode newMode) => _commitFilterModeProperty.value = newMode;

  /// Returns true if the filter is hiding or showing commits based on their match.
  bool get isFilteringCommits =>
      _commitFilterModeProperty.value == CommitFilterMode.filter &&
          _allCommitProperties.any((ValueFilterProperty<dynamic> property) => !property.isDefault);

  /// Returns true if the filter is highlighting commits based on their match.
  bool get isHighlightingCommits =>
      _commitFilterModeProperty.value == CommitFilterMode.highlight &&
          _allCommitProperties.any((ValueFilterProperty<dynamic> property) => !property.isDefault);

  /// Check the values in the [Commit] for compatibility with the properties of this
  /// filter and return [true] iff the commit row should be displayed.
  bool matchesCommit(Commit commit) {
    if (!_authorProperty.matches(commit.author)) {
      return false;
    }
    if (!_messageProperty.matches(commit.message)) {
      return false;
    }
    if (!_hashProperty.matches(commit.sha)) {
      return false;
    }
    return true;
  }

  /// Check the values in the [QualifiedTask] for compatibility with the properties of this
  /// filter and return [true] iff the commit column should be displayed.
  bool matchesTask(QualifiedTask qualifiedTask) {
    return _taskProperty.matches(qualifiedTask.task);
  }

  /// Convert the filter into a String map (with or without default values populated) that
  /// can be used to reconstruct the filter using the [fromMap] constructor and/or inject
  /// its data into a JSON file or URL query parameter list.
  Map<String, String> toMap({bool includeDefaults = true}) => Map<String, String>.fromEntries(_allProperties.entries
      .where((MapEntry<String, ValueFilterProperty<dynamic>> element) => includeDefaults || !element.value.isDefault)
      .map((MapEntry<String, ValueFilterProperty<dynamic>> e) => MapEntry<String, String>(e.key, e.value.stringValue)));

  /// A string useful for including in a URL as query parameters. The returned string will
  /// include only non-default filter values separated by the URL parameter separator (`&`).
  /// The string will not include the leading `?` character used to introduce URL parameters
  /// in case this string must be mixed with other query parameters.
  String get queryParameters => toMap(includeDefaults: false)
      .entries
      .map<String>((MapEntry<String, String> e) => '${e.key}=${e.value}')
      .join('&');

  List<FilterPropertyNode> _layout;

  /// Return the list of properties of this filter in a form that can be used by a
  /// [FilterPropertySheet] to display the fields to a user and allow them to edit the values.
  @override
  List<FilterPropertyNode> get sheetLayout => _layout ??= <FilterPropertyNode>[
    _taskProperty,
    _authorProperty,
    _messageProperty,
    _hashProperty,
    _commitFilterModeProperty,
  ];

  // [_allProperties] is a LinkedHashMap so we can trust its iteration order
  String get _values => _allProperties.values
      .where((ValueFilterProperty<dynamic> element) => !element.isDefault)
      .map((ValueFilterProperty<dynamic> e) => e.stringValue)
      .join(', ');

  @override
  String toString() => 'TaskGridFilter($_values)';

  // [_allProperties] is a LinkedHashMap so we can trust its iteration order
  @override
  int get hashCode => hashList(_allProperties.values.map((ValueFilterProperty<dynamic> e) => e.value));

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is TaskGridFilter &&
        _allProperties.values.every(
            (ValueFilterProperty<dynamic> element) => element.value == other._allProperties[element.fieldName].value);
  }

  List<VoidCallback> _listeners;

  void notifyListeners() {
    if (_listeners != null) {
      for (final VoidCallback listener in _listeners) {
        listener();
      }
    }
  }

  @override
  void addListener(VoidCallback listener) {
    if (_listeners == null) {
      _listeners = <VoidCallback>[];
      for (final ValueFilterProperty<dynamic> property in _allProperties.values) {
        property.addListener(notifyListeners);
      }
    }
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners?.remove(listener);
  }
}
