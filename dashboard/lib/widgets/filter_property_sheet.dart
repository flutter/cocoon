// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Bridge between the [FilterPropertySheet] and a filter object that has a number of
/// properties by which it filters lists. The [sheetLayout] provides both the properties
/// to be displayed and edited and also a suggestion for their layout.
abstract class FilterPropertySource extends Listenable {
  /// The list of properties exposed by the filter for editing.
  List<FilterPropertyNode> get sheetLayout;
}

/// The base class for all elements in a [FilterPropertySheet]. Most of the nodes will
/// be value properties, but some may be layout nodes.
///
/// @see [ValueFilterProperty], [FilterPropertyGroup]
abstract mixin class FilterPropertyNode {
  /// The descriptive name of the property or layout group as will be displayed
  /// in the [FilterPropertySheet].
  String? get label;
}

/// The abstract base class of all valued properties, useful for both displaying them
/// in and editing them from a [FilterPropertySheet] and methods to make them useful
/// as the actual storage for the properties in a filter object. A filter object then
/// becomes mostly a list of these properties along with methods to combine them into
/// predicates for filtering data in a dashboard or other list.
///
/// @see [RegExpFilterProperty], [BoolFilterProperty]
abstract class ValueFilterProperty<T> extends ValueListenable<T> with FilterPropertyNode {
  ValueFilterProperty({required this.fieldName, this.label});

  /// The name of the field represented by this property, used to import and export
  /// the property values via maps.
  final String fieldName;

  @override
  final String? label;

  /// The value of the property converted to a [String] useful for importing and
  /// exporting the values via maps and JSON files.
  String get stringValue;
  set stringValue(String newValue);

  /// Whether the property is set to its default value.
  bool get isDefault;

  /// Resets this property to its default value;
  void reset();

  List<VoidCallback>? _listeners;

  @override
  void addListener(VoidCallback listener) {
    _listeners ??= <VoidCallback>[];
    _listeners!.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners?.remove(listener);
  }

  /// Notify all listeners that the value of the property has changed.
  void notifyListeners() {
    if (_listeners != null) {
      for (final VoidCallback listener in _listeners!) {
        listener();
      }
    }
  }
}

/// A class used to represent a Regular Expression property in the filter object.
class RegExpFilterProperty extends ValueFilterProperty<String?> {
  RegExpFilterProperty({required super.fieldName, super.label, String? value, bool caseSensitive = true})
      : _value = value,
        _caseSensitive = caseSensitive;

  String? _value;
  final bool _caseSensitive;
  @override
  String? get value => _value;
  set value(String? newValue) {
    if (newValue == '') {
      newValue = null;
    }
    if (_value != newValue) {
      _value = newValue;
      _regExp = null;
      notifyListeners();
    }
    newValue ??= '';
    if (_controller != null && _controller!.text != newValue) {
      _controller!.text = newValue;
      // The listener callback should nop
    }
  }

  TextEditingController? _controller;
  TextEditingController? get controller {
    if (_controller == null) {
      _controller = TextEditingController(text: stringValue);
      _controller!.addListener(() {
        value = _controller!.text;
      });
    }
    return _controller;
  }

  @override
  String get stringValue => _value ?? '';

  @override
  set stringValue(String newValue) => value = newValue;

  @override
  bool get isDefault => _value == null;

  @override
  void reset() => value = null;

  /// The value of this property as a [RegExp] object, useful for matching its pattern
  /// against candidate values in the list being filtered.
  RegExp? _regExp;
  RegExp? get regExp => _regExp ??= _value == null ? null : RegExp(_value!, caseSensitive: _caseSensitive);
  set regExp(RegExp? newRegExp) => value = newRegExp == null || newRegExp.pattern == '' ? null : newRegExp.pattern;

  /// True iff the value, interpreted as a regular expression, matches the candidate [String].
  bool matches(String candidate) => regExp?.hasMatch(candidate) ?? true;
}

/// A class used to represent a boolean property in the filter object.
class BoolFilterProperty extends ValueFilterProperty<bool?> {
  BoolFilterProperty({required super.fieldName, super.label, bool value = true})
      : _value = value,
        _defaultValue = value;

  bool? _value;
  final bool? _defaultValue;

  @override
  bool? get value => _value;
  set value(bool? newValue) {
    if (_value != newValue) {
      _value = newValue;
      notifyListeners();
    }
  }

  @override
  String get stringValue => _value.toString();

  @override
  set stringValue(String newValue) {
    if (newValue == 'true' || newValue == 't') {
      value = true;
    } else if (newValue == 'false' || newValue == 'f') {
      value = false;
    } else {
      throw 'Unrecognized bool value: $newValue';
    }
  }

  @override
  bool get isDefault => value == _defaultValue;

  @override
  void reset() => value = _defaultValue;
}

/// A class used to enclose a group of other [BoolFilterProperty] properties to be
/// presented in a more compact format in the property sheet.
class BoolFilterPropertyGroup extends FilterPropertyNode {
  BoolFilterPropertyGroup({this.label, this.members});

  @override
  final String? label;

  /// The boolean property members of this group.
  final List<BoolFilterProperty>? members;
}

/// A [Widget] used to display the values of the properties of a filter object and to allow
/// a user to edit those properties. The changes are recorded in new filter objects using the
/// [FilterPropertySource.copyWithMap] method and communicated back to the app live via
/// modifying the value of the [filterNotifier].
///
/// If an optional [onClose] callback is supplied, this sheet will include its own close control
/// and notify the creator when it is closed via the callback. Otherwise the creator is
/// responsible for the lifecycle of this sheet.
class FilterPropertySheet extends StatefulWidget {
  const FilterPropertySheet(this.propertySource, {this.onClose, super.key});

  /// The notifier object used to get the initial value of the filter properties and to
  /// send back new filter objects with modified values as the user edits the fields.
  final FilterPropertySource? propertySource;

  /// The optional callback for when the close field on the sheet is used to close the
  /// sheet. This [Widget] will only implement its own close box if this callback is non-null.
  final Function()? onClose;

  @override
  State createState() => FilterPropertySheetState();
}

class FilterPropertySheetState extends State<FilterPropertySheet> {
  @override
  void initState() {
    super.initState();

    widget.propertySource!.addListener(_update);
  }

  @override
  void dispose() {
    widget.propertySource!.removeListener(_update);

    super.dispose();
  }

  static const TextStyle _labelStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  void _update() {
    setState(() {});
  }

  Widget _pad(Widget child, Alignment alignment) {
    return Container(
      padding: const EdgeInsets.all(5.0),
      alignment: alignment,
      child: child,
    );
  }

  TableRow _makeRow(String label, Widget editable) {
    return TableRow(
      children: <Widget>[
        _pad(Text(label, style: _labelStyle), Alignment.centerRight),
        _pad(editable, Alignment.centerLeft),
      ],
    );
  }

  TableRow _makeTextFilterRow(RegExpFilterProperty property) {
    return _makeRow(
      property.label!,
      TextField(
        autofocus: true,
        controller: property.controller,
        decoration: const InputDecoration(
          hintText: '(JavaScript regular expression)',
        ),
        onChanged: (String value) => property.value = value,
      ),
    );
  }

  TableRow _makeBoolRow(BoolFilterProperty property) {
    return _makeRow(
      property.label!,
      Checkbox(
        value: property.value,
        onChanged: (bool? newValue) => property.value = newValue,
      ),
    );
  }

  Widget _makeLoneCheckbox(BoolFilterProperty property) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(property.label!, style: _labelStyle),
        Checkbox(
          value: property.value,
          onChanged: (bool? newValue) => property.value = newValue,
        ),
      ],
    );
  }

  TableRow _makeTableRow(FilterPropertyNode property) {
    if (property is RegExpFilterProperty) {
      return _makeTextFilterRow(property);
    }
    if (property is BoolFilterProperty) {
      return _makeBoolRow(property);
    }
    if (property is BoolFilterPropertyGroup) {
      return _makeRow(
        property.label!,
        Wrap(
          children: property.members!.map<Widget>(_makeLoneCheckbox).toList(),
        ),
      );
    }
    throw 'unrecognized FilterProperty: $property';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        if (widget.onClose != null)
          Positioned(
            child: TextButton(
              onPressed: widget.onClose,
              child: const Icon(Icons.close),
            ),
          ),
        Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const <int, TableColumnWidth>{
            0: IntrinsicColumnWidth(),
            1: FixedColumnWidth(300.0),
          },
          children: widget.propertySource!.sheetLayout.map(_makeTableRow).toList(),
        ),
      ],
    );
  }
}
