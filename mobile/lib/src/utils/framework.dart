// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// A RequestOnce widget calls a callback on initState.
class RequestOnce extends StatefulWidget {
  const RequestOnce({
    @required this.child,
    @required this.callback,
  });

  final void Function() callback;
  final Widget child;

  @override
  State<StatefulWidget> createState() {
    return _RequestOnceState();
  }
}

class _RequestOnceState extends State<RequestOnce> {
  @override
  void initState() {
    widget.callback();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

