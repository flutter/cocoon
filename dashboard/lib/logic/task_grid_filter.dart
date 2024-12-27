// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../logic/qualified_task.dart';
import '../model/commit_status.pb.dart';
import '../widgets/filter_property_sheet.dart';

/// A filter object for controlling which entries are visible in the Build dashboard grid
/// of tasks. This filter object can filter on a number of properties of the tasks including
/// the name of the task, information on the commit that generated the tasks, and platform
/// stage type toggles.
class TaskGridFilter extends FilterPropertySource {
  TaskGridFilter();

  factory TaskGridFilter.fromMap(Map<String, String>? valueMap) =>
      TaskGridFilter()..applyMap(valueMap);

  /// True iff all of the properties of the filter are set to their default values.
  bool get isDefault => _allProperties.values
      .toList()
      .every((ValueFilterProperty<dynamic> element) => element.isDefault);

  /// Sets all properties of this filter to their default values.
  void reset() {
    for (final ValueFilterProperty<dynamic> property in _allProperties.values) {
      property.reset();
    }
  }

  /// Modifies this filter based on the values in the map. If the map is null, no changes are
  /// made. All keys in the [valueMap] must match one of the field names of the filter properties.
  void applyMap(Map<String, String>? valueMap) {
    if (valueMap != null) {
      for (final MapEntry<String, String> mapEntry in valueMap.entries) {
        if (_allProperties.containsKey(mapEntry.key)) {
          _allProperties[mapEntry.key]!.stringValue = mapEntry.value;
        }
      }
    }
  }

  final RegExpFilterProperty _taskProperty = RegExpFilterProperty(
      fieldName: 'taskFilter', label: 'Task Name', caseSensitive: false);
  final RegExpFilterProperty _authorProperty = RegExpFilterProperty(
      fieldName: 'authorFilter', label: 'Commit Author', caseSensitive: false);
  final RegExpFilterProperty _messageProperty = RegExpFilterProperty(
      fieldName: 'messageFilter',
      label: 'Commit Message',
      caseSensitive: false);
  final RegExpFilterProperty _hashProperty =
      RegExpFilterProperty(fieldName: 'hashFilter', label: 'Commit Hash');
  final BoolFilterProperty _macProperty =
      BoolFilterProperty(fieldName: 'showMac', label: 'Mac');
  final BoolFilterProperty _windowsPorperty =
      BoolFilterProperty(fieldName: 'showWindows', label: 'Windows');
  final BoolFilterProperty _iosProperty =
      BoolFilterProperty(fieldName: 'showiOS', label: 'iOS');
  final BoolFilterProperty _linuxPorperty =
      BoolFilterProperty(fieldName: 'showLinux', label: 'Linux');
  final BoolFilterProperty _androidProperty =
      BoolFilterProperty(fieldName: 'showAndroid', label: 'Android');
  final BoolFilterProperty _bringUpProperty = BoolFilterProperty(
      fieldName: 'showBringup', label: 'Bring Up', value: false);
  final BoolFilterProperty _stagingProperty = BoolFilterProperty(
      fieldName: 'showStaging', label: 'Staging', value: false);

  // [_allProperties] is a LinkedHashMap so we can trust its iteration order
  LinkedHashMap<String, ValueFilterProperty<dynamic>>? _allPropertiesMap;

  LinkedHashMap<String, ValueFilterProperty<dynamic>> get _allProperties =>
      (_allPropertiesMap ??= (<String, ValueFilterProperty<dynamic>>{}
            ..[_taskProperty.fieldName] = _taskProperty
            ..[_authorProperty.fieldName] = _authorProperty
            ..[_messageProperty.fieldName] = _messageProperty
            ..[_hashProperty.fieldName] = _hashProperty
            ..[_macProperty.fieldName] = _macProperty
            ..[_windowsPorperty.fieldName] = _windowsPorperty
            ..[_iosProperty.fieldName] = _iosProperty
            ..[_linuxPorperty.fieldName] = _linuxPorperty
            ..[_androidProperty.fieldName] = _androidProperty
            ..[_stagingProperty.fieldName] = _stagingProperty
            ..[_bringUpProperty.fieldName] = _bringUpProperty)
          as LinkedHashMap<String, ValueFilterProperty<dynamic>>?)!;

  /// The [taskFilter] property is a regular expression that must match the name of the
  /// task in the grid. This property will filter out columns on the build dashboard.
  RegExp? get taskFilter => _taskProperty.regExp;

  set taskFilter(RegExp? regExp) => _taskProperty.regExp = regExp;

  /// The [authorFilter] property is a regular expression that must match the name of the
  /// author of the task's commit. This property will filter out rows on the build dashboard.
  RegExp? get authorFilter => _authorProperty.regExp;

  set authorFilter(RegExp? regExp) => _authorProperty.regExp = regExp;

  /// The [messageFilter] property is a regular expression that must match the commit message
  /// of the task's commit. This property will filter out rows on the build dashboard.
  RegExp? get messageFilter => _messageProperty.regExp;

  set messageFilter(RegExp? regExp) => _messageProperty.regExp = regExp;

  /// The [hashFilter] property is a regular expression that must match the hash of the
  /// task's commit. This property will filter out rows on the build dashboard.
  RegExp? get hashFilter => _hashProperty.regExp;

  set hashFilter(RegExp? regExp) => _hashProperty.regExp = regExp;

  /// The [showWindows] property is a boolean
  ///
  /// it indicates whether to display tasks produced by a Windows stage in the devicelab.
  /// This property will filter out columns on the build dashboard.
  bool? get showWindows => _windowsPorperty.value;

  set showWindows(bool? value) => _windowsPorperty.value = value;

  /// The [showMac] property is a boolean
  ///
  /// it indicates whether to display tasks produced by a Mac stage in the devicelab.
  /// This property will filter out columns on the build dashboard.
  bool? get showMac => _macProperty.value;

  set showMac(bool? value) => _macProperty.value = value;

  /// The [showiOS] property is a boolean
  ///
  /// it indicates whether to display tasks produced by an iOS stage in the devicelab.
  /// This property will filter out columns on the build dashboard.
  bool? get showiOS => _iosProperty.value;

  set showiOS(bool? value) => _iosProperty.value = value;

  /// The [showLinux] property is a boolean
  ///
  /// it indicates whether to display tasks produced by a Linux stage in the devicelab.
  /// This property will filter out columns on the build dashboard.
  bool? get showLinux => _linuxPorperty.value;

  set showLinux(bool? value) => _linuxPorperty.value = value;

  /// The [showAndroid] property is a boolean
  ///
  /// it indicates whether to display tasks produced by an Android stage in the devicelab.
  /// This property will filter out columns on the build dashboard.
  bool? get showAndroid => _androidProperty.value;

  set showAndroid(bool? value) => _androidProperty.value = value;

  /// The [showStaging] property is a boolean
  ///
  /// it indicates whether to display staging tasks (tasks with name prefixed
  /// with linux_staging_build).
  /// This property will filter out columns on the build dashboard.
  bool? get showStaging => _stagingProperty.value;

  set showStaging(bool? value) => _stagingProperty.value = value;

  /// Whether to display tasks that are marked `bringup` (do not block the tree).
  ///
  /// This property will filter out columns on the build dashboard.
  bool? get showBringup => _bringUpProperty.value;

  set showBringup(bool? value) => _bringUpProperty.value = value;

  /// Check the values in the [CommitStatus] for compatibility with the properties of this
  /// filter and return [true] iff the commit row should be displayed.
  bool matchesCommit(CommitStatus commitStatus) {
    if (!_authorProperty.matches(commitStatus.commit.author)) {
      return false;
    }
    if (!_messageProperty.matches(commitStatus.commit.message)) {
      return false;
    }
    if (!_hashProperty.matches(commitStatus.commit.sha)) {
      return false;
    }
    return true;
  }

  /// Check the values in the [QualifiedTask] for compatibility with the
  /// properties of this filter and return [true] iff the commit column should be displayed.
  bool matchesTask(QualifiedTask qualifiedTask) {
    if (!_taskProperty.matches(qualifiedTask.task!)) {
      return false;
    }

    if ((!_allProperties['showStaging']?.value) &&
        qualifiedTask.task!.toLowerCase().startsWith('staging_build_')) {
      return false;
    }

    if ((!_allProperties['showBringup']?.value) && qualifiedTask.isBringup) {
      return false;
    }

    final bool showAndroid = _allProperties['showAndroid']?.value ?? false;
    final LinkedHashMap<String, bool> orderedOSFilter =
        LinkedHashMap<String, bool>.of({
      'ios': _allProperties['showiOS']?.value ?? false,
      'android': showAndroid,
      'mokey': showAndroid,
      'pixel_7pro': showAndroid,
      'mac': _allProperties['showMac']?.value ?? false,
      'windows': _allProperties['showWindows']?.value ?? false,
      'linux': _allProperties['showLinux']?.value ?? false,
    });
    return orderedOSFilter.entries
            .firstWhereOrNull((MapEntry<String, bool> os) =>
                qualifiedTask.task!.toLowerCase().contains(os.key))
            ?.value ??
        true; // Unrecognized stages always pass.
  }

  /// Convert the filter into a String map (with or without default values populated) that
  /// can be used to reconstruct the filter using the [fromMap] constructor and/or inject
  /// its data into a JSON file or URL query parameter list.
  Map<String, String> toMap() => Map<String, String>.fromEntries(
        _allProperties.entries
            .where(
              (MapEntry<String, ValueFilterProperty<dynamic>> element) =>
                  !element.value.isDefault,
            )
            .map(
              (MapEntry<String, ValueFilterProperty<dynamic>> e) =>
                  MapEntry<String, String>(e.key, e.value.stringValue),
            ),
      );

  /// A string useful for including in a URL as query parameters. The returned string will
  /// include only non-default filter values separated by the URL parameter separator (`&`).
  /// The string will not include the leading `?` character used to introduce URL parameters
  /// in case this string must be mixed with other query parameters.
  String get queryParameters => toMap()
      .entries
      .map<String>((MapEntry<String?, String> e) => '${e.key}=${e.value}')
      .join('&');

  List<FilterPropertyNode>? _layout;

  /// Return the list of properties of this filter in a form that can be used by a
  /// [FilterPropertySheet] to display the fields to a user and allow them to edit the values.
  @override
  List<FilterPropertyNode> get sheetLayout => _layout ??= <FilterPropertyNode>[
        _taskProperty,
        _authorProperty,
        _messageProperty,
        _hashProperty,
        BoolFilterPropertyGroup(
          label: 'Stages',
          members: <BoolFilterProperty>[
            _androidProperty,
            _iosProperty,
            _linuxPorperty,
            _macProperty,
            _windowsPorperty,
            _stagingProperty,
            _bringUpProperty,
          ],
        ),
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
  int get hashCode => Object.hashAll(
      _allProperties.values.map((ValueFilterProperty<dynamic> e) => e.value));

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is TaskGridFilter &&
        _allProperties.values.every(
          (ValueFilterProperty<dynamic> element) =>
              element.value == other._allProperties[element.fieldName]!.value,
        );
  }

  List<VoidCallback>? _listeners;

  void notifyListeners() {
    if (_listeners != null) {
      for (final VoidCallback listener in _listeners!) {
        listener();
      }
    }
  }

  @override
  void addListener(VoidCallback listener) {
    if (_listeners == null) {
      _listeners = <VoidCallback>[];
      for (final ValueFilterProperty<dynamic> property
          in _allProperties.values) {
        property.addListener(notifyListeners);
      }
    }
    _listeners!.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners?.remove(listener);
  }
}
