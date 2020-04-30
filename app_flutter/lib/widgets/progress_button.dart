// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

typedef AsyncVoidCallback = Future<void> Function();

/// A [RaisedButton] whose [onPressed] returns a [Future], and which
/// overlays a progress indicator when the button is pressed until the
/// future completes.
///
/// Technically this violates the Material design guidelines six ways
/// to Sunday but...
class ProgressButton extends StatefulWidget {
  const ProgressButton({
    Key key,
    this.child,
    this.onPressed,
  }) : super(key: key);

  final Widget child;

  final AsyncVoidCallback onPressed;

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
    widget.onPressed().whenComplete(() {
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
        RaisedButton(
          child: widget.child,
          onPressed:
              _busy ? null : widget.onPressed != null ? _handlePressed : null,
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
