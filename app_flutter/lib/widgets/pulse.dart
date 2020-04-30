// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Shows a pulsating circle of the given color.
///
/// Used on the [TaskGrid] to show active tasks.
class Pulse extends StatefulWidget {
  const Pulse({
    Key key,
    this.color = const Color(0xFF000000),
  }) : super(key: key);

  final Color color;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      lowerBound: 0.0,
      upperBound: math.pi * 2.0,
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      if (_controller.isAnimating) {
        _controller.value = math.pi; // half-way
      }
    } else {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget child) {
        final double t =
            math.sin(_controller.value) / 4.0 + 0.75; // from 0.5 to 1.0
        return Transform.scale(
          scale: t,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: const CircleBorder(),
              color: widget.color.withOpacity(t),
            ),
          ),
        );
      },
    );
  }
}
