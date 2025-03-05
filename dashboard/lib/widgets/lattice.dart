// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'task_box.dart';

typedef Painter = void Function(Canvas canvas, Rect rect);

typedef LatticeTapCallback = void Function(Offset? offset);

/// A cell in a [LatticeScrollView].
@immutable
class LatticeCell extends _LatticeCell {
  const LatticeCell({
    super.painter,
    this.builder,
    super.onTap,
    this.taskName,
  });

  final WidgetBuilder? builder;

  final String? taskName;

  @override
  bool get hasChild => builder != null;
}

/// A bidirectional scrollable view that draws arrays of arrays of [LatticeCell]s.
///
/// Only the [cells] that are visible are drawn.
///
/// The cells will be sized according to [cellSize].
class LatticeScrollView extends StatelessWidget {
  const LatticeScrollView({
    super.key,
    this.horizontalPhysics,
    this.horizontalController,
    this.textDirection,
    this.verticalPhysics,
    this.verticalController,
    this.dragStartBehavior = DragStartBehavior.start,
    required this.cells,
  });

  final ScrollPhysics? horizontalPhysics;

  final ScrollController? horizontalController;

  final TextDirection? textDirection;

  final ScrollPhysics? verticalPhysics;

  final ScrollController? verticalController;

  final DragStartBehavior dragStartBehavior;

  final List<List<LatticeCell>> cells;

  @override
  Widget build(BuildContext context) {
    final textDirection = this.textDirection ?? Directionality.of(context);
    return Scrollbar(
      controller: horizontalController,
      thumbVisibility: true,
      child: Scrollable(
        dragStartBehavior: dragStartBehavior,
        axisDirection: textDirectionToAxisDirection(textDirection),
        controller: horizontalController,
        physics: horizontalPhysics,
        scrollBehavior: _MouseDragScrollBehavior.instance,
        viewportBuilder:
            (BuildContext context, ViewportOffset horizontalOffset) =>
                NotificationListener<OverscrollNotification>(
          onNotification: (notification) =>
              notification.metrics.axisDirection != AxisDirection.right &&
              notification.metrics.axisDirection != AxisDirection.left,
          child: Scrollbar(
            thumbVisibility: true,
            controller: verticalController,
            child: Scrollable(
              dragStartBehavior: dragStartBehavior,
              axisDirection: AxisDirection.down,
              controller: verticalController,
              physics: verticalPhysics,
              scrollBehavior: _MouseDragScrollBehavior.instance,
              viewportBuilder:
                  (BuildContext context, ViewportOffset verticalOffset) =>
                      _LatticeBody(
                textDirection: textDirection,
                horizontalOffset: horizontalOffset,
                verticalOffset: verticalOffset,
                cells: cells,
                cellSize: Size.square(TaskBox.of(context)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Used to mark classes that would be made public if the rendering object side
/// of this contraption is ever made public.
const Object _public = Object();

@_public
class _LatticeBody extends RenderObjectWidget {
  const _LatticeBody({
    required this.textDirection,
    required this.horizontalOffset,
    required this.verticalOffset,
    required this.cells,
    required this.cellSize,
  });

  final TextDirection textDirection;
  final ViewportOffset horizontalOffset;
  final ViewportOffset verticalOffset;
  final List<List<LatticeCell>> cells;
  final Size cellSize;

  @override
  _RenderLatticeBody createRenderObject(BuildContext context) {
    return _RenderLatticeBody(
      textDirection: textDirection,
      horizontalOffset: horizontalOffset,
      verticalOffset: verticalOffset,
      cells: cells,
      cellSize: cellSize,
      delegate: context as _LatticeBodyElement,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderLatticeBody renderObject) {
    renderObject
      ..textDirection = textDirection
      ..horizontalOffset = horizontalOffset
      ..verticalOffset = verticalOffset
      ..cells = cells
      ..cellSize = cellSize
      ..delegate = context as _LatticeBodyElement;
  }

  @override
  RenderObjectElement createElement() => _LatticeBodyElement(this);
}

@_public
class _LatticeBodyElement extends RenderObjectElement
    implements _LatticeDelegate {
  _LatticeBodyElement(_LatticeBody super.widget);

  @override
  _LatticeBody get widget => super.widget as _LatticeBody;

  @override
  _RenderLatticeBody get renderObject =>
      super.renderObject as _RenderLatticeBody;

  // This element uses _Coordinate objects as slots.

  Map<Key?, Element?> _newChildrenByKey = <Key?, Element?>{};
  Map<Key?, Element?>? _oldChildrenByKey;
  Map<_Coordinate, Element?> _newChildrenByCoordinate =
      <_Coordinate, Element?>{};
  Map<_Coordinate, Element?>? _oldChildrenByCoordinate;

  @override
  void beginLayout() {
    _oldChildrenByKey = _newChildrenByKey;
    _newChildrenByKey = <Key?, Element?>{};
    _oldChildrenByCoordinate = _newChildrenByCoordinate;
    _newChildrenByCoordinate = <_Coordinate, Element?>{};
  }

  @override
  RenderBox? updateLatticeChild(
      _Coordinate coordinate, LatticeCell cell, RenderBox? oldChild) {
    Widget? newWidget;
    Element? newElement;
    owner!.buildScope(this, () {
      try {
        newWidget = cell.builder!(this);
        debugWidgetBuilderValue(widget, newWidget);
      } catch (exception, stack) {
        newWidget = ErrorWidget.builder(
          _debugReportException(
            FlutterErrorDetails(
              context:
                  ErrorDescription('building cell $coordinate for $widget'),
              exception: exception,
              stack: stack,
              library: 'Flutter Dashboard',
              informationCollector: () sync* {
                yield DiagnosticsDebugCreator(DebugCreator(this));
              },
            ),
          ),
        );
      }
      Element? oldElement;
      if (newWidget!.key != null) {
        oldElement = _oldChildrenByKey![newWidget!.key];
        if (oldElement != null) {
          _oldChildrenByKey![newWidget!.key] =
              null; // null indicates it exists but is not in the grid
          _oldChildrenByCoordinate!.remove(oldElement.slot as _Coordinate?);
        }
      } else {
        oldElement = _oldChildrenByCoordinate![coordinate];
        if (oldElement != null && oldElement.widget.key != null) {
          oldElement = null;
        }
        _oldChildrenByCoordinate!.remove(coordinate);
      }
      try {
        newElement = updateChild(oldElement, newWidget, coordinate);
      } catch (e, stack) {
        newWidget = ErrorWidget.builder(
          _debugReportException(
            FlutterErrorDetails(
              context: ErrorDescription(
                  'building widget $newWidget at cell $coordinate for $widget'),
              exception: e,
              stack: stack,
              library: 'Flutter Dashboard',
              informationCollector: () sync* {
                yield DiagnosticsDebugCreator(DebugCreator(this));
              },
            ),
          ),
        );
        newElement = updateChild(null, newWidget, slot);
      }
    });
    assert(newElement!.slot == coordinate);
    if (newWidget!.key != null) {
      _newChildrenByKey[newWidget!.key] = newElement;
    }
    _newChildrenByCoordinate[coordinate] = newElement;
    return newElement!.renderObject as RenderBox?;
  }

  @override
  void endLayout() {
    for (final oldChild in _oldChildrenByCoordinate!.values) {
      if (oldChild!.widget.key == null) {
        updateChild(oldChild, null, null);
      }
    }
    for (final oldChild in _oldChildrenByKey!.values) {
      updateChild(oldChild, null, null);
    }
    _oldChildrenByKey = null;
    _oldChildrenByCoordinate = null;
  }

  @override
  void forgetChild(Element child) {
    if (child.widget.key != null) {
      _newChildrenByKey.remove(child.widget.key);
    }
    _newChildrenByCoordinate.remove(child.slot as _Coordinate?);
    super.forgetChild(child);
  }

  @override
  void insertRenderObjectChild(RenderObject child, _Coordinate? slot) {
    renderObject.placeChild(null, slot, null, child as RenderBox);
  }

  @override
  void moveRenderObjectChild(
      RenderObject child, _Coordinate? oldSlot, _Coordinate? newSlot) {
    renderObject.placeChild(
        oldSlot, newSlot, child as RenderBox?, child as RenderBox);
  }

  @override
  void removeRenderObjectChild(RenderObject child, _Coordinate? slot) {
    renderObject.removeChild(slot, child as RenderBox);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    (_newChildrenByCoordinate.values.whereType<Element>().toList()
          ..sort(_compareChildren))
        .forEach(visitor);
  }

  int _compareChildren(Element a, Element b) {
    final aSlot = a.slot as _Coordinate;
    final bSlot = b.slot as _Coordinate;
    return aSlot.compareTo(bSlot);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final children = _newChildrenByCoordinate.values
        .whereType<Element>()
        .toList()
      ..sort(_compareChildren);
    return children.map((Element? child) {
      return child!.toDiagnosticsNode(
          name: child.slot != null ? '${child.slot}' : '(lost)');
    }).toList();
  }
}

@immutable
@_public
class _Coordinate implements Comparable<_Coordinate> {
  const _Coordinate(this.x, this.y);

  final int x;

  final int y;

  @override
  int compareTo(_Coordinate other) {
    if (y == other.y) {
      return x - other.x;
    }
    return y - other.y;
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _Coordinate && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';

  Offset asOffset(Size cellSize) =>
      Offset(x.toDouble() * cellSize.width, y.toDouble() * cellSize.height);
}

@_public
class _LatticeParentData extends ParentData {
  _Coordinate? coordinate;
}

@immutable
@_public
class _LatticeCell {
  const _LatticeCell({
    this.painter,
    this.onTap,
  });

  static const _LatticeCell empty = _LatticeCell();

  final Painter? painter;

  final LatticeTapCallback? onTap;

  @protected
  bool get hasChild => false;
}

@_public
abstract class _LatticeDelegate {
  const _LatticeDelegate();
  void beginLayout();
  RenderBox? updateLatticeChild(
      _Coordinate coordinate, covariant _LatticeCell cell, RenderBox? oldChild);
  void endLayout();
}

@_public
class _RenderLatticeBody extends RenderBox {
  _RenderLatticeBody({
    required TextDirection textDirection,
    required ViewportOffset horizontalOffset,
    required ViewportOffset verticalOffset,
    required List<List<_LatticeCell>> cells,
    required Size cellSize,
    required _LatticeDelegate delegate,
  })  : assert(!cellSize.isEmpty),
        _textDirection = textDirection,
        _horizontalOffset = horizontalOffset,
        _verticalOffset = verticalOffset,
        _cells = cells,
        _cellSize = cellSize,
        _delegate = delegate {
    _handleOffsetChange();
    _recomputeCellDimensions();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) {
      return;
    }
    _textDirection = value;
    markNeedsPaint();
  }

  ViewportOffset get horizontalOffset => _horizontalOffset;
  ViewportOffset _horizontalOffset;
  set horizontalOffset(ViewportOffset value) {
    if (value == _horizontalOffset) {
      return;
    }
    if (attached) {
      _horizontalOffset.removeListener(_handleOffsetChange);
    }
    _horizontalOffset = value;
    if (attached) {
      _horizontalOffset.addListener(_handleOffsetChange);
    }
    _handleOffsetChange();
  }

  ViewportOffset get verticalOffset => _verticalOffset;
  ViewportOffset _verticalOffset;
  set verticalOffset(ViewportOffset value) {
    if (value == _verticalOffset) {
      return;
    }
    if (attached) {
      _verticalOffset.removeListener(_handleOffsetChange);
    }
    _verticalOffset = value;
    if (attached) {
      _verticalOffset.addListener(_handleOffsetChange);
    }
    _handleOffsetChange();
  }

  int _cellWidthCount = 0, _cellHeightCount = 0;

  List<List<_LatticeCell>> get cells => _cells;
  List<List<_LatticeCell>> _cells;
  set cells(List<List<_LatticeCell>> value) {
    if (value == _cells) {
      return;
    }
    _cells = value;
    markNeedsLayout();
    _recomputeCellDimensions();
  }

  void _recomputeCellDimensions() {
    _cellWidthCount = cells.fold<int>(0,
        (int current, List<_LatticeCell> row) => math.max(current, row.length));
    _cellHeightCount = cells.length;
    _handleOffsetChange();
  }

  Size get cellSize => _cellSize;
  Size _cellSize;
  set cellSize(Size value) {
    assert(!value.isEmpty);
    if (value == _cellSize) {
      return;
    }
    _cellSize = value;
    markNeedsLayout();
  }

  _LatticeDelegate get delegate => _delegate;
  _LatticeDelegate _delegate;
  set delegate(_LatticeDelegate value) {
    if (value == _delegate) {
      return;
    }
    _delegate = value;
    markNeedsLayout();
  }

  // TODO(ianh): rather than store and paint the children directly in
  // this render object, dynamically create _RenderLatticeTiles that
  // handle cacheStride x cacheStride sections of the grid. This would
  // give us more efficient scrolling since we would not need to
  // update them. We would need to make sure to mark them all as
  // needing layout when the list of widgets changed.
  //
  // Currently, we have to repaint everything when we scroll because
  // we have no way to cache the paint in a layer.

  _LatticeCell? _getCellFor(_Coordinate coordinate) {
    if (coordinate.y < 0 || coordinate.x < 0) {
      return null;
    }
    if (coordinate.y >= cells.length) {
      return null;
    }
    if (coordinate.x >= cells[coordinate.y].length) {
      return null;
    }
    return cells[coordinate.y][coordinate.x];
  }

  bool _hasTapHandler(_Coordinate coordinate) {
    return _getCellFor(coordinate)?.onTap != null;
  }

  final Map<_Coordinate?, RenderBox> _childrenByCoordinate =
      <_Coordinate?, RenderBox>{};

  void placeChild(_Coordinate? oldCoordinate, _Coordinate? newCoordinate,
      RenderBox? oldChild, RenderBox newChild) {
    if (oldChild == newChild) {
      return;
    }
    if (oldChild != null) {
      final oldChildParentData = oldChild.parentData as _LatticeParentData;
      oldChildParentData.coordinate = null;
    }
    if (oldCoordinate != null) {
      _childrenByCoordinate.remove(oldCoordinate);
    }
    _childrenByCoordinate[newCoordinate] = newChild;
    if (newChild.parent != this) {
      adoptChild(newChild);
    }
    final newChildParentData = newChild.parentData as _LatticeParentData;
    newChildParentData.coordinate = newCoordinate;
  }

  void removeChild(_Coordinate? coordinate, RenderBox child) {
    if (coordinate != null) {
      _childrenByCoordinate.remove(coordinate);
    }
    dropChild(child);
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! ParentData) {
      child.parentData = _LatticeParentData();
    }
  }

  TapGestureRecognizer? _tap;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _horizontalOffset.addListener(_handleOffsetChange);
    _verticalOffset.addListener(_handleOffsetChange);
    _tap = TapGestureRecognizer(debugOwner: this)
      ..onTapDown = _handleTapDown
      ..onTapUp = _handleTapUp;
    for (final child in _childrenByCoordinate.values) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    _horizontalOffset.removeListener(_handleOffsetChange);
    _verticalOffset.removeListener(_handleOffsetChange);
    _tap?.dispose();
    for (final child in _childrenByCoordinate.values) {
      child.detach();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _clipLabelColumnHandle.layer = null;
    _clipLabelRowHandle.layer = null;
    _clipDataHandle.layer = null;
  }

  @override
  void redepthChildren() {
    _childrenByCoordinate.values.forEach(redepthChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    _childrenByCoordinate.values.forEach(visitor);
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  double computeMinIntrinsicWidth(double? height) {
    return _cellWidthCount * cellSize.width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return computeMinIntrinsicWidth(height);
  }

  @override
  double computeMinIntrinsicHeight(double? width) {
    return _cellHeightCount * cellSize.height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return computeMinIntrinsicHeight(width);
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = Size(
      constraints.hasBoundedWidth
          ? constraints.maxWidth
          : constraints.constrainWidth(computeMinIntrinsicWidth(null)),
      constraints.hasBoundedHeight
          ? constraints.maxHeight
          : constraints.constrainHeight(computeMinIntrinsicHeight(null)),
    );
    horizontalOffset.applyViewportDimension(size.width);
    verticalOffset.applyViewportDimension(size.height);
    _handleOffsetChange(duringLayout: true);
  }

  Offset? _scrollOffset;
  int? _firstX, _firstY, _lastX, _lastY;

  void _handleOffsetChange({bool duringLayout = false}) {
    if (!hasSize) {
      assert(_scrollOffset == null);
      return;
    }
    final scrollOffset = Offset(horizontalOffset.pixels, verticalOffset.pixels);
    final firstX = scrollOffset.dx ~/ cellSize.width;
    final lastX = ((scrollOffset.dx + size.width) / cellSize.width).ceil() - 1;
    final firstY = scrollOffset.dy ~/ cellSize.height;
    final lastY = math.min(
            ((scrollOffset.dy + size.height) / cellSize.height).ceil(),
            _cellHeightCount) -
        1;
    if (scrollOffset != _scrollOffset) {
      _scrollOffset = scrollOffset;
      markNeedsPaint();
    }
    if (firstX != _firstX ||
        lastX != _lastX ||
        firstY != _firstY ||
        lastY != _lastY) {
      _firstX = firstX;
      _lastX = lastX;
      _firstY = firstY;
      _lastY = lastY;
      if (!duringLayout) {
        markNeedsLayout();
      }
    }
  }

  @override
  void performLayout() {
    assert(_scrollOffset != null);
    final childConstraints = BoxConstraints.tight(cellSize);
    invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
      delegate.beginLayout();
    });
    for (var y = 0; y < _cellHeightCount; y += 1) {
      for (var x = 0; x < _cellWidthCount; x += 1) {
        final here = _Coordinate(x, y);
        final visible = (x == 0 || x >= _firstX!) &&
            x <= _lastX! &&
            (y == 0 || y >= _firstY!) &&
            y <= _lastY!;
        assert(y < cells.length);
        final cell = x < cells[y].length ? cells[y][x] : _LatticeCell.empty;
        if (visible && cell.hasChild) {
          RenderBox? child;
          invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
            child = delegate.updateLatticeChild(
                here, cell, _childrenByCoordinate[here]);
          });
          assert(child != null);
          assert(child!.parent == this);
          assert(_childrenByCoordinate[here] == child);
          child!.layout(childConstraints);
        }
      }
    }
    invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
      delegate.endLayout();
    });
    horizontalOffset.applyContentDimensions(
      0.0,
      math.max(0.0, computeMinIntrinsicWidth(null) - size.width),
    );
    verticalOffset.applyContentDimensions(
      0.0,
      math.max(0.0, computeMinIntrinsicHeight(null) - size.height),
    );
  }

  final LayerHandle<ClipRectLayer> _clipLabelRowHandle =
      LayerHandle<ClipRectLayer>();
  final LayerHandle<ClipRectLayer> _clipLabelColumnHandle =
      LayerHandle<ClipRectLayer>();
  final LayerHandle<ClipRectLayer> _clipDataHandle =
      LayerHandle<ClipRectLayer>();

  void _paintCell(PaintingContext context, Offset offset, int x, int y) {
    final here = _Coordinate(x, y);
    assert(y < cells.length);
    final cell = x < cells[y].length ? cells[y][x] : _LatticeCell.empty;
    final topLeft = _coordinateToOffset(here)! + offset;
    final painter = cell.painter;
    final child = cell.hasChild ? _childrenByCoordinate[here] : null;
    assert(child == _childrenByCoordinate[here]);
    assert(cell.hasChild == (child != null));
    if (painter != null) {
      painter(context.canvas, topLeft & cellSize);
    }
    if (child != null) {
      context.paintChild(child, topLeft);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(needsCompositing);
    final dataOffset = Offset(cellSize.width, cellSize.height);
    final dataSize = size - dataOffset as Size;
    if (dataSize.isEmpty) {
      return;
    }
    _clipLabelColumnHandle.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Rect.fromLTWH(0, dataOffset.dy, cellSize.width, dataSize.height),
      (PaintingContext context, Offset offset) {
        for (int y = max(1, _firstY!); y <= _lastY!; y += 1) {
          _paintCell(context, offset, 0, y);
        }
      },
      oldLayer: _clipLabelColumnHandle.layer,
    );
    _clipLabelRowHandle.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Rect.fromLTWH(dataOffset.dx, 0, dataSize.width, cellSize.height),
      (PaintingContext context, Offset offset) {
        for (int x = max(1, _firstX!); x <= _lastX!; x += 1) {
          _paintCell(context, offset, x, 0);
        }
      },
      oldLayer: _clipLabelRowHandle.layer,
    );
    _clipDataHandle.layer = context.pushClipRect(
      needsCompositing,
      offset,
      dataOffset & dataSize,
      (PaintingContext context, Offset offset) {
        for (var y = _firstY! + 1; y <= _lastY!; y += 1) {
          for (var x = _firstX! + 1; x <= _lastX!; x += 1) {
            _paintCell(context, offset, x, y);
          }
        }
      },
      oldLayer: _clipDataHandle.layer,
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final childParentData = child.parentData as _LatticeParentData;
    final offset = _coordinateToOffset(childParentData.coordinate!)!;
    transform.translate(offset.dx, offset.dy);
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) => Offset.zero & size;

  @override
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    if (descendant != null) {
      // TODO(ianh): Implement this. Not having this implemented means
      // accessibility scrolling won't work for this viewport.
      //
      // The implementation should honor allowImplicitScrolling on
      // horizontalOffset and verticalOffset, descendant and rect, and
      // duration and curve. (If duration is Duration.zero, use jumpTo
      // on the offsets, otherwise use animateTo.)
    }
    super.showOnScreen(
      rect: rect,
      duration: duration,
      curve: curve,
    );
  }

  _Coordinate? _offsetToCoordinate(Offset? position) {
    late Offset absolute;
    switch (textDirection) {
      case TextDirection.rtl:
        absolute = Offset(
            position!.dx - _scrollOffset!.dx, position.dy + _scrollOffset!.dy);
        break;
      case TextDirection.ltr:
        absolute = position! + _scrollOffset!;
        break;
    }
    switch (textDirection) {
      case TextDirection.rtl:
        return _Coordinate(
          position.dx + cellSize.width > size.width
              ? 0
              : (size.width - absolute.dx) ~/ cellSize.width,
          position.dy < cellSize.height ? 0 : absolute.dy ~/ cellSize.height,
        );
      case TextDirection.ltr:
        return _Coordinate(
          position.dx < cellSize.width ? 0 : absolute.dx ~/ cellSize.width,
          position.dy < cellSize.height ? 0 : absolute.dy ~/ cellSize.height,
        );
    }
  }

  Offset? _coordinateToOffset(_Coordinate coordinate) {
    final adjustedScroll = Offset(
      coordinate.x == 0 ? 0 : _scrollOffset!.dx,
      coordinate.y == 0 ? 0 : _scrollOffset!.dy,
    );
    switch (textDirection) {
      case TextDirection.rtl:
        return Offset(
          size.width -
              (coordinate.x * cellSize.width) -
              cellSize.width +
              adjustedScroll.dx,
          coordinate.y * cellSize.height - adjustedScroll.dy,
        );
      case TextDirection.ltr:
        return Offset(
              coordinate.x * cellSize.width,
              coordinate.y * cellSize.height,
            ) -
            adjustedScroll;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset? position}) {
    final coordinate = _offsetToCoordinate(position);
    final child = _childrenByCoordinate[coordinate];
    return child != null &&
        result.addWithPaintOffset(
          offset: _coordinateToOffset(coordinate!),
          position: position!,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            return child.hitTest(result, position: transformed);
          },
        );
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    final coordinate = _offsetToCoordinate(event.localPosition);
    if (event is PointerDownEvent && _hasTapHandler(coordinate!)) {
      _tap?.addPointer(event);
    }
  }

  _Coordinate? _lastTapDown;

  void _handleTapDown(TapDownDetails details) {
    _lastTapDown = _offsetToCoordinate(details.localPosition);
  }

  void _handleTapUp(TapUpDetails details) {
    final lastTapUp = _offsetToCoordinate(details.localPosition);
    if (_lastTapDown == lastTapUp && _hasTapHandler(lastTapUp!)) {
      _getCellFor(_lastTapDown!)!.onTap!(_coordinateToOffset(lastTapUp));
    }
  }

  @override
  Rect describeSemanticsClip(RenderObject? child) =>
      (Offset.zero & size).inflate(cellSize.longestSide);
}

FlutterErrorDetails _debugReportException(FlutterErrorDetails details) {
  FlutterError.reportError(details);
  return details;
}

/// A [MaterialScrollBehavior] that supports mouse dragging.
class _MouseDragScrollBehavior extends MaterialScrollBehavior {
  static _MouseDragScrollBehavior? _instance;
  static _MouseDragScrollBehavior get instance =>
      _instance ??= _MouseDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
