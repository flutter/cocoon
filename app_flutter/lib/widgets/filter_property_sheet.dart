// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Bridge between the [FilterPropertySheet] and a filter object that has a number of
/// properties by which it filters lists. The methods here provide all of the information
/// that the FilterPropertySheet needs to display the various properties in some sort
/// of editing dialog and to let the user edit them.
abstract class FilterPropertySource {
  /// The list of properties exposed by the filter for editing.
  List<FilterProperty> get properties;

  /// Returns a [String] representation for any field according to the [FilterProperty.fieldName]
  /// in its associated [FilterProperty] object, even those properties that are not inherently
  /// strings.
  String getString(String fieldName);

  /// Returns a [bool] representation for any field associated with a [BoolFilterProperty].
  bool getBool(String fieldName);

  /// Returns a new instance of the filter object with the indicated properties changed
  /// to new values according to the entries in the map.
  FilterPropertySource copyWithMap(Map<String, String> valueMap);
}

/// The abstract base class of all properties, establishing that they will all (usually)
/// have a [fieldName] and a [label].
///
/// @see [RegExpFilterProperty], [BoolFilterProperty], [FilterPropertyGroup]
abstract class FilterProperty {
  const FilterProperty({this.fieldName, this.label});

  /// The name of the field represented by this property, used to get and modify that
  /// field.
  final String fieldName;

  /// The descriptive name of the property as will be displayed in the [FilterPropertySheet].
  final String label;

  /// An indication as to whether a [TextEditingController] needs to be instantiated
  /// to facilitate editing this property (only true for string valued fields).
  bool get needsController => false;
}

/// A class used to represent a Regular Expression property in the filter object.
class RegExpFilterProperty extends FilterProperty {
  const RegExpFilterProperty({String fieldName, String label}) : super(fieldName: fieldName, label: label);

  @override
  bool get needsController => true;
}

/// A class used to represent a boolean property in the filter object.
class BoolFilterProperty extends FilterProperty {
  const BoolFilterProperty({String fieldName, String label}) : super(fieldName: fieldName, label: label);
}

/// A class used to enclose a group of other [BoolFilterProperty] properties to be
/// presented in a more compact format in the property sheet.
class BoolFilterPropertyGroup extends FilterProperty {
  const BoolFilterPropertyGroup({String label, this.members}) : super(label: label);

  final List<BoolFilterProperty> members;
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
  const FilterPropertySheet(this.filterNotifier, {this.onClose});

  /// The notifier object used to get the initial value of the filter properties and to
  /// send back new filter objects with modified values as the user edits the fields.
  final ValueNotifier<FilterPropertySource> filterNotifier;

  /// The optional callback for when the close field on the sheet is used to close the
  /// sheet. This [Widget] will only implement its own close box if this callback is non-null.
  final Function() onClose;

  @override
  State createState() => FilterPropertySheetState();
}

class FilterPropertySheetState extends State<FilterPropertySheet> {
  @override
  void initState() {
    super.initState();

    widget.filterNotifier.addListener(_update);
    _resetControllers();
  }

  @override
  void dispose() {
    widget.filterNotifier.removeListener(_update);

    super.dispose();
  }

  static const TextStyle _labelStyle = TextStyle(
    color: Colors.black,
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  FilterPropertySource get _filter => widget.filterNotifier.value;
  final Map<String, TextEditingController> _controllers = <String, TextEditingController>{};

  void _update() {
    setState(() {
      _resetControllers();
    });
  }

  void _initController(FilterProperty property) {
    // BoolFilterProperty group has no members that need a controller so we do not need to recurse.
    if (property.needsController) {
      TextEditingController controller = _controllers[property.fieldName];
      final String value = _filter.getString(property.fieldName) ?? '';
      if (controller == null) {
        controller = TextEditingController(text: value);
        _controllers[property.fieldName] = controller;
      } else if (controller.text != value) {
        controller.text = value;
      }
    }
  }

  void _resetControllers() {
    _filter.properties.forEach(_initController);
  }

  void _newValue(String fieldName, String valueString) {
    widget.filterNotifier.value = _filter.copyWithMap(<String, String>{fieldName: valueString});
  }

  void _newBoolValue(String fieldName, bool newValue) {
    _newValue(fieldName, newValue.toString());
  }

  Widget _pad(Widget child, Alignment alignment) {
    return Container(
      padding: const EdgeInsets.all(5.0),
      child: child,
      alignment: alignment,
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

  TableRow _makeTextFilterRow(FilterProperty property) {
    return _makeRow(
      property.label,
      TextField(
        controller: _controllers[property.fieldName],
        decoration: const InputDecoration(
          hintText: '(regular expression)',
        ),
        onChanged: (String newValue) => _newValue(property.fieldName, newValue),
      ),
    );
  }

  TableRow _makeBoolRow(FilterProperty property) {
    return _makeRow(
      property.label,
      Checkbox(
        value: _filter.getBool(property.fieldName),
        onChanged: (bool newValue) => _newBoolValue(property.fieldName, newValue),
      ),
    );
  }

  Widget _makeLoneCheckbox(BoolFilterProperty property) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(property.label, style: _labelStyle),
        Checkbox(
          value: _filter.getBool(property.fieldName),
          onChanged: (bool newValue) => _newBoolValue(property.fieldName, newValue),
        ),
      ],
    );
  }

  TableRow _makeTableRow(FilterProperty property) {
    if (property is RegExpFilterProperty) {
      return _makeTextFilterRow(property);
    }
    if (property is BoolFilterProperty) {
      return _makeBoolRow(property);
    }
    if (property is BoolFilterPropertyGroup) {
      return _makeRow(
        property.label,
        Wrap(
          children: property.members.map<Widget>(_makeLoneCheckbox).toList(),
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
            child: FlatButton(
              child: const Icon(Icons.close),
              onPressed: widget.onClose,
            ),
          ),
        Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const <int, TableColumnWidth>{
            0: IntrinsicColumnWidth(),
            1: FixedColumnWidth(300.0),
          },
          children: _filter.properties.map(_makeTableRow).toList(),
        ),
      ],
    );
  }
}
