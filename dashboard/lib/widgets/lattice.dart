// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'task_box.dart';

typedef Painter = void Function(Canvas canvas, Rect rect);

typedef LatticeTapCallback = void Function(Offset? offset);

/// A cell in a [LatticeScrollView].
@immutable
class LatticeCell {
  const LatticeCell({this.painter, this.builder, this.onTap, this.taskName});

  final Painter? painter;
  final WidgetBuilder? builder;
  final LatticeTapCallback? onTap;
  final String? taskName;

  bool get hasChild => builder != null;

  static const LatticeCell empty = LatticeCell();
}

class _LatticeVerticalScrollPhysics extends ScrollPhysics {
  const _LatticeVerticalScrollPhysics({super.parent});

  @override
  _LatticeVerticalScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _LatticeVerticalScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    final isShiftPressed =
        keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight) ||
        HardwareKeyboard.instance.isShiftPressed;

    if (isShiftPressed) {
      return false;
    }
    return super.shouldAcceptUserOffset(position);
  }
}

/// A bidirectional scrollable view that draws arrays of arrays of [LatticeCell]s.
///
/// Implemented using [TableView.builder] from `two_dimensional_scrollables`.
class LatticeScrollView extends StatelessWidget {
  const LatticeScrollView({
    super.key,
    this.horizontalPhysics,
    this.horizontalController,
    this.textDirection,
    this.verticalPhysics,
    this.verticalController,
    this.dragStartBehavior = DragStartBehavior.start,
    this.cacheExtent = 250.0,
    required this.cells,
  });

  final ScrollPhysics? horizontalPhysics;
  final ScrollController? horizontalController;
  final TextDirection? textDirection;
  final ScrollPhysics? verticalPhysics;
  final ScrollController? verticalController;
  final DragStartBehavior dragStartBehavior;
  final double cacheExtent;
  final List<List<LatticeCell>> cells;

  bool get _isShiftPressed {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    return keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight) ||
        HardwareKeyboard.instance.isShiftPressed;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event case final PointerScrollEvent scrollEvent) {
      final delta = _isShiftPressed && scrollEvent.scrollDelta.dy != 0
          ? scrollEvent.scrollDelta.dy
          : scrollEvent.scrollDelta.dx;

      if (delta != 0 &&
          horizontalController != null &&
          horizontalController!.hasClients) {
        GestureBinding.instance.pointerSignalResolver.register(event, (
          PointerSignalEvent event,
        ) {
          final current = horizontalController!.offset;
          final maxScroll = horizontalController!.position.maxScrollExtent;
          final target = (current + delta).clamp(0.0, maxScroll);
          horizontalController!.jumpTo(target);
        });
      }
    }
  }

  void _handleTapUp(TapUpDetails details, double cellSize) {
    final scrollX = horizontalController?.hasClients == true
        ? horizontalController!.offset
        : 0.0;
    final scrollY = verticalController?.hasClients == true
        ? verticalController!.offset
        : 0.0;

    final dx = details.localPosition.dx;
    final dy = details.localPosition.dy;

    final int col;
    if (dx <= cellSize) {
      col = 0;
    } else {
      col = ((dx - cellSize + scrollX) / cellSize).floor() + 1;
    }

    final int row;
    if (dy <= cellSize) {
      row = 0;
    } else {
      row = ((dy - cellSize + scrollY) / cellSize).floor() + 1;
    }

    if (row >= 0 && row < cells.length && col >= 0 && col < cells[row].length) {
      final cell = cells[row][col];
      if (cell.onTap != null) {
        final screenX = col == 0 ? 0.0 : (col * cellSize - scrollX);
        final screenY = row == 0 ? 0.0 : (row * cellSize - scrollY);
        cell.onTap!(Offset(screenX, screenY));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty || cells.first.isEmpty) {
      return const SizedBox.shrink();
    }

    final rowCount = cells.length;
    final columnCount = cells.fold<int>(
      0,
      (max, row) => math.max(max, row.length),
    );

    final cellSize = TaskBox.of(context);
    final span = TableSpan(extent: FixedTableSpanExtent(cellSize));

    final effectiveVerticalPhysics = _LatticeVerticalScrollPhysics(
      parent: verticalPhysics ?? const ClampingScrollPhysics(),
    );

    return RepaintBoundary(
      child: Listener(
        onPointerSignal: _handlePointerSignal,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (TapUpDetails details) => _handleTapUp(details, cellSize),
          child: Scrollbar(
            controller: horizontalController,
            thumbVisibility: true,
            notificationPredicate: (notification) =>
                notification.metrics.axis == Axis.horizontal,
            child: Scrollbar(
              controller: verticalController,
              thumbVisibility: true,
              notificationPredicate: (notification) =>
                  notification.metrics.axis == Axis.vertical,
              child: TableView.builder(
                cacheExtent: cacheExtent,
                diagonalDragBehavior: DiagonalDragBehavior.free,
                pinnedRowCount: rowCount > 1 ? 1 : 0,
                pinnedColumnCount: columnCount > 1 ? 1 : 0,
                columnCount: columnCount,
                rowCount: rowCount,
                rowBuilder: (int row) => span,
                columnBuilder: (int column) => span,
                cellBuilder: (BuildContext context, TableVicinity vicinity) {
                  final y = vicinity.row;
                  final x = vicinity.column;

                  if (y >= cells.length || x >= cells[y].length) {
                    return TableViewCell(
                      key: ValueKey<TableVicinity>(vicinity),
                      addRepaintBoundaries: false,
                      child: const SizedBox.shrink(),
                    );
                  }

                  final cell = cells[y][x];
                  Widget child;

                  if (cell.builder != null) {
                    final innerChild = cell.builder!(context);
                    if (cell.painter != null) {
                      child = _LatticeCellChildBox(
                        cellSize: cellSize,
                        painter: cell.painter,
                        child: innerChild,
                      );
                    } else {
                      child = innerChild;
                    }
                  } else if (cell.painter != null) {
                    child = _LatticeCellBox(
                      cellSize: cellSize,
                      painter: cell.painter,
                    );
                  } else {
                    child = const SizedBox.shrink();
                  }

                  return TableViewCell(
                    key: ValueKey<TableVicinity>(vicinity),
                    addRepaintBoundaries: false,
                    child: Listener(
                      onPointerSignal: _handlePointerSignal,
                      child: child,
                    ),
                  );
                },
                verticalDetails: ScrollableDetails.vertical(
                  controller: verticalController,
                  physics: effectiveVerticalPhysics,
                ),
                horizontalDetails: ScrollableDetails.horizontal(
                  controller: horizontalController,
                  physics: horizontalPhysics,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LatticeCellBox extends LeafRenderObjectWidget {
  const _LatticeCellBox({required this.cellSize, this.painter});

  final double cellSize;
  final Painter? painter;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderLatticeCellBox(cellSize: cellSize, painter: painter);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLatticeCellBox renderObject,
  ) {
    renderObject
      ..cellSize = cellSize
      ..painter = painter;
  }
}

class _RenderLatticeCellBox extends RenderBox {
  _RenderLatticeCellBox({required double cellSize, Painter? painter})
    : _cellSize = cellSize,
      _painter = painter;

  double get cellSize => _cellSize;
  double _cellSize;
  set cellSize(double value) {
    if (_cellSize == value) return;
    _cellSize = value;
    markNeedsLayout();
  }

  Painter? get painter => _painter;
  Painter? _painter;
  set painter(Painter? value) {
    if (_painter == value) return;
    _painter = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    size = Size(cellSize, cellSize);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_painter != null) {
      _painter!(context.canvas, offset & size);
    }
  }
}

class _LatticeCellChildBox extends SingleChildRenderObjectWidget {
  const _LatticeCellChildBox({
    required this.cellSize,
    this.painter,
    required Widget super.child,
  });

  final double cellSize;
  final Painter? painter;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderLatticeCellChildBox(cellSize: cellSize, painter: painter);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLatticeCellChildBox renderObject,
  ) {
    renderObject
      ..cellSize = cellSize
      ..painter = painter;
  }
}

class _RenderLatticeCellChildBox extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderLatticeCellChildBox({required double cellSize, Painter? painter})
    : _cellSize = cellSize,
      _painter = painter;

  double get cellSize => _cellSize;
  double _cellSize;
  set cellSize(double value) {
    if (_cellSize == value) return;
    _cellSize = value;
    markNeedsLayout();
  }

  Painter? get painter => _painter;
  Painter? _painter;
  set painter(Painter? value) {
    if (_painter == value) return;
    _painter = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    size = Size(cellSize, cellSize);
    child?.layout(BoxConstraints.tight(size), parentUsesSize: false);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_painter != null) {
      _painter!(context.canvas, offset & size);
    }
    if (child != null) {
      context.paintChild(child!, offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return child?.hitTest(result, position: position) ?? false;
  }
}
