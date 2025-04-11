// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../helpers/invoke_if_non_null.dart';

/// Displays and invokes [onSelect] for an item of [T].
///
/// Renders like the following if nothing is selected:
/// ```txt
/// ---------------------------
/// | Filter by typing...     |
/// ---------------------------
/// ```
///
/// Renders like the following if something is selected:
/// ```txt
/// ---------------------------
/// | Item 1                x |
/// ---------------------------
/// ```
///
/// This widget is intended to be updated with [selected].
final class DropdownSelect<T> extends StatelessWidget {
  const DropdownSelect({
    required this.options,
    required this.itemBuilder,
    required this.labelBuilder,
    required this.selected,
    this.onSelect,
  });

  /// Options that can be selected.
  final List<T> options;

  /// Returns a [Widget] representing the item for [T].
  ///
  /// ## Example
  ///
  /// ```dart
  /// TappableSelect(
  ///   itemBuilder: (item) => Text(item.name),
  /// )
  /// ```
  final Widget Function(T) itemBuilder;

  /// Returns a string label representing the item for [T].
  ///
  /// Workaround for https://github.com/flutter/flutter/issues/166999.
  final String Function(T) labelBuilder;

  /// Currently selected element of type [T].
  final T selected;

  /// Invoked when an item is selected.
  ///
  /// If `null` this select is read only.
  final void Function(T)? onSelect;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu(
      hintText: 'Select a branch',
      dropdownMenuEntries: [
        ...options.map((option) {
          return DropdownMenuEntry(
            value: option,
            label: labelBuilder(option),
            labelWidget: itemBuilder(option),
          );
        }),
      ],
      enableFilter: true,
      initialSelection: selected,
      onSelected: invokeIfNonNull(onSelect),
      label: const Text('Branch'),
    );
  }
}
