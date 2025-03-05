// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

typedef AsyncVoidCallback = Future<void> Function();

/// An [ElevatedButton] whose [onPressed] returns a [Future], and which
/// overlays a progress indicator when the button is pressed until the
/// future completes.
///
/// Technically this violates the Material design guidelines six ways
/// to Sunday but...
class ProgressButton extends StatefulWidget {
  const ProgressButton({
    super.key,
    this.child,
    this.onPressed,
  });

  final Widget? child;

  final AsyncVoidCallback? onPressed;

  @override
  State<ProgressButton> createState() => _ProgressButtonState();
}

class _ProgressButtonState extends State<ProgressButton> {
  bool _busy = false;

  void _handlePressed() {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
    });
    widget.onPressed!().whenComplete(() {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    });
  }

  static const Widget _progressIndicator = Padding(
    padding: EdgeInsets.all(12.0),
    child: Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: CircularProgressIndicator(),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ElevatedButton(
          onPressed: _busy // dartfmt will soon require this new formatting
              ? null
              : widget.onPressed !=
                      null // dartfmt will soon require this new formatting
                  ? _handlePressed
                  : null,
          child: widget.child,
        ),
        if (_busy)
          const Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: _progressIndicator,
          ),
      ],
    );
  }
}
