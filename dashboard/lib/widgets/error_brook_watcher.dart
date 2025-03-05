// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../logic/brooks.dart';

/// Show error messages as snackbars.
///
/// This widget must be a descendant of a [Scaffold].
///
/// The [errors] brook is watched and any messages sent to that brook
/// are displayed as [SnackBar]s on the nearest [Scaffold].
class ErrorBrookWatcher extends StatefulWidget {
  const ErrorBrookWatcher({
    super.key,
    this.errors,
    this.child,
  });

  final Brook<String>? errors;

  final Widget? child;

  @visibleForTesting
  static const Duration errorSnackbarDuration = Duration(seconds: 8);

  @override
  State<ErrorBrookWatcher> createState() => _ErrorBrookWatcherState();
}

class _ErrorBrookWatcherState extends State<ErrorBrookWatcher> {
  @override
  void initState() {
    super.initState();
    widget.errors!.addListener(_showErrorSnackbar);
  }

  @override
  void didUpdateWidget(ErrorBrookWatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errors != oldWidget.errors) {
      oldWidget.errors!.removeListener(_showErrorSnackbar);
      widget.errors!.addListener(_showErrorSnackbar);
    }
  }

  @override
  void dispose() {
    widget.errors!.removeListener(_showErrorSnackbar);
    super.dispose();
  }

  void _showErrorSnackbar(String error) {
    final snackbarContent = Row(
      children: <Widget>[
        const Icon(Icons.error),
        const SizedBox(width: 10),
        Text(error),
      ],
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: snackbarContent,
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: ErrorBrookWatcher.errorSnackbarDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child!;
  }
}
