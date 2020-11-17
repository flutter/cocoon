// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class _ModelBindingScope<T> extends InheritedWidget {
  const _ModelBindingScope({Key key, this.modelBindingState, Widget child}) : super(key: key, child: child);

  final _ModelBindingState<T> modelBindingState;

  @override
  bool updateShouldNotify(_ModelBindingScope<T> oldWidget) => true;
}

class ModelBinding<T> extends StatefulWidget {
  const ModelBinding({
    Key key,
    @required this.initialModel,
    this.child,
  })  : assert(initialModel != null),
        super(key: key);

  final T initialModel;
  final Widget child;

  @override
  _ModelBindingState<T> createState() => _ModelBindingState<T>();

  static T of<T>(BuildContext context) {
    if (context == null) {
      // The widget is not in the tree.
      return null;
    }

    final _ModelBindingScope<T> scope = context.dependOnInheritedWidgetOfExactType<_ModelBindingScope<T>>();
    return scope.modelBindingState.currentModel;
  }

  static void update<T>(BuildContext context, T newModel) {
    if (context == null) {
      // The widget is not in the tree.
      return;
    }
    final _ModelBindingScope<T> scope = context.dependOnInheritedWidgetOfExactType<_ModelBindingScope<T>>();
    scope.modelBindingState.updateModel(newModel);
  }
}

class _ModelBindingState<T> extends State<ModelBinding<T>> {
  T currentModel;

  @override
  void initState() {
    super.initState();
    currentModel = widget.initialModel;
  }

  void updateModel(T newModel) {
    if (newModel != currentModel) {
      setState(() {
        currentModel = newModel;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ModelBindingScope<T>(
      modelBindingState: this,
      child: widget.child,
    );
  }
}
