// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../helpers/invoke_if_non_null.dart';

/// Displays and invokes [onSelect] for an item of [T].
///
/// Renders like the following:
/// ```txt
/// ---------------------------
/// | Filter by typing...     |
/// ---------------------------
/// | Item 1                > |
/// | Item 2                > |
/// | Item 3                > |
/// ---------------------------
/// ```
///
/// This widget is intended to be replaced and/or provide navigation, and as
/// such does not have a _currently selected_ property, as one does not exist.
final class TappableSelect<T> extends StatefulWidget {
  TappableSelect({
    required this.options,
    required this.itemBuilder,
    required this.onSelect,
  }) : onFilter = null,
       initialFilter = null;

  TappableSelect.withFiltering({
    required this.options,
    required this.itemBuilder,
    required this.onSelect,
    required bool Function(T, String) onFilter,
    this.initialFilter,
    // This is actually not the same, it's non-null in the constructor.
    // ignore: prefer_initializing_formals
  }) : onFilter = onFilter;

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

  /// Invoked when an item is selected.
  final void Function(T) onSelect;

  /// If provided, returns if the provided string should match an item.
  final bool Function(T, String)? onFilter;

  /// The initial value provided to [onFilter], or `null` not to filter.
  final String? initialFilter;

  @override
  State<TappableSelect<T>> createState() {
    return _TappableState();
  }
}

final class _TappableState<T> extends State<TappableSelect<T>> {
  final _filterController = TextEditingController();
  List<T> _filteredOptions = [];

  @override
  void initState() {
    _filterController.addListener(_updateFilteredOptions);
    if (widget.initialFilter case final filterByText?) {
      _filterController.text = filterByText;
    } else {
      _updateFilteredOptions();
    }
    super.initState();
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _updateFilteredOptions() {
    if (_filterController.text.isEmpty) {
      setState(() {
        _filteredOptions = widget.options;
      });
      return;
    }

    setState(() {
      _filteredOptions = [
        ...widget.options.where((option) {
          return widget.onFilter!(option, _filterController.text);
        }),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      // Take minimal vertical space necessary.
      mainAxisSize: MainAxisSize.min,

      children: [
        // Conditional: Filtering.
        if (widget.onFilter != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _filterController,
              decoration: InputDecoration(
                hintText: 'Select a repo',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _filterController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _filterController.clear,
                        )
                        : null,
              ),
            ),
          ),

        Flexible(
          child: ListView.builder(
            itemCount: _filteredOptions.length,
            itemBuilder: (_, index) {
              final item = _filteredOptions[index];
              return ListTile(
                onTap: invokeWithItem(item, widget.onSelect),
                title: widget.itemBuilder(item),
                trailing: const Icon(Icons.chevron_right),
              );
            },
          ),
        ),
      ],
    );
  }
}
