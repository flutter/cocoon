// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../entities.dart';
import '../utils/semantics.dart';

class BenchmarkChart extends StatefulWidget {
  const BenchmarkChart({
    Key key,
    @required this.data,
    this.rounded = true,
    this.onBarChanged,
  }) : super(key: key);

  final BenchmarkData data;
  final bool rounded;
  final void Function(int) onBarChanged;

  @override
  BenchmarkChartState createState() {
    return BenchmarkChartState();
  }
}

class BenchmarkChartState extends State<BenchmarkChart> {
  void _onIndexChanged(int newIndex) {
    widget?.onBarChanged(newIndex);
  }

  @override
  Widget build(BuildContext context) {
    var recent = widget.data.values.last.value;
    var baseline = widget.data.timeseries.timeseries.baseline;
    var goal = widget.data.timeseries.timeseries.goal;
    var unit = widget.data.timeseries.timeseries.unit;
    String phrase;
    if (recent < goal) {
      phrase = 'below goal at';
    } else if (recent < baseline) {
      phrase = 'below baseline but above goal at';
    } else {
      phrase = 'above baseline at';
    }
    phrase += '$recent ${unitAbbreviationToName(unit)}';
    Widget chart = BarChart(
      data: widget.data,
      onBarHover: _onIndexChanged,
    );
    if (widget.rounded) {
      chart = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BarChart(
          data: widget.data,
          onBarHover: _onIndexChanged,
        ),
      );
    }
    return Semantics(
      container: true,
      label: phrase,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 160,
          maxHeight: 160,
          minWidth: double.infinity,
        ),
        child: chart,
      ),
    );
  }
}

class BarChart extends SingleChildRenderObjectWidget {
  const BarChart({
    @required this.data,
    @required this.onBarHover,
  });

  final void Function(int) onBarHover;
  final BenchmarkData data;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderBarChart()
      ..data = data
      ..onBarHover = onBarHover;
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderBarChart renderObject) {
    renderObject
      ..data = data
      ..onBarHover = onBarHover;
  }
}

class RenderBarChart extends RenderProxyBox {
  RenderBarChart() {
    var team = GestureArenaTeam();
    _drag = HorizontalDragGestureRecognizer(debugOwner: this)
      ..team = team
      ..onUpdate = _handleDragUpdate;
  }
  HorizontalDragGestureRecognizer _drag;
  bool get _isInteractive => onBarHover != null;
  double _maxValue;
  double _hoverDx = 0;
  double _barWidth = 1;
  int _hoverIndex = 0;

  BenchmarkData get data => _data;
  BenchmarkData _data;
  set data(BenchmarkData value) {
    if (value == _data) {
      return;
    }
    _data = value;
    _computeMaxValue();
    markNeedsPaint();
  }

  void Function(int) onBarHover;

  void _computeMaxValue() {
    var max = _data.timeseries.timeseries.baseline;
    for (var value in _data.values) {
      if (value.value > max) {
        max = value.value;
      }
    }
    max *= 1.1;
    _maxValue = max;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var canvas = context.canvas;
    canvas.save();
    if (offset != Offset.zero) {
      canvas.translate(offset.dx, offset.dy);
    }
    _paintChart(canvas, size);
    canvas.restore();
  }

  void _paintChart(Canvas canvas, Size size) {
    var rounded = size < const Size(100, 100);
    var grey = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF757083);
    var red = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.redAccent;
    var rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.grey[200]);
    _barWidth = rect.width / (_data.values.isNotEmpty ? _data.values.length : 1.0); // width of each bar.
    var scale = rect.height / _maxValue; // px/unit
    Rect hoverRect;
    var dx = 0.0; // offset from left side of chart.
    for (var i = 0; i < _data.values.length; i++) {
      var timeseriesValue = _data.values[i];
      var value = timeseriesValue.value;
      if (timeseriesValue.isDataMissing || timeseriesValue.value.isNaN) {
        value = 0;
      }
      var isPassing = value < data.timeseries.timeseries.baseline;
      if (value != 0 && !value.isNaN) {
        var height = value * scale;
        var bar = Rect.fromLTWH(dx - 0.2, rect.height - height, _barWidth + 0.4, height);
        canvas.drawRect(bar, isPassing ? grey : red);
      }
      if (_hoverIndex == i) {
        hoverRect = Rect.fromLTWH(dx - 0.2, 0, _barWidth + 0.4, rect.height);
      }
      dx += _barWidth;
    }
    if (hoverRect != null && !rounded) {
      canvas.drawRect(
          hoverRect,
          Paint()
            ..color = Colors.orangeAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    if (rounded) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(16)),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.black54,
      );
    } else {
      canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.black54,
      );
    }
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent && _isInteractive) {
      _drag.addPointer(event);
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _hoverDx = globalToLocal(details.globalPosition).dx;
    var rectWidth = _barWidth;
    var hoverIndex = (_hoverDx / rectWidth).round();
    if (hoverIndex < 0) {
      hoverIndex = 0;
    } else if (hoverIndex >= data.values.length) {
      hoverIndex = data.values.length - 1;
    }
    if (_hoverIndex != hoverIndex) {
      _hoverIndex = hoverIndex;
      onBarHover(hoverIndex);
      markNeedsPaint();
    }
  }

  @override
  bool hitTestSelf(Offset position) => true;
}
