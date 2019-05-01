import 'package:flutter/material.dart';

const double _kMinFlingVelocity = 700.0;
const double _kMinFlingVelocityDelta = 400.0;
const double _kFlingVelocityScale = 1.0 / 300.0;
const double _kDismissThreshold = 0.4;

class SlideActions extends StatefulWidget {
  const SlideActions({
    @required Key key,
    @required this.child,
    this.background,
    this.onResize,
    this.direction = DismissDirection.horizontal,
    this.movementDuration = const Duration(milliseconds: 200),
    this.crossAxisEndOffset = 0.0,
  }) : assert(key != null),
       super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// A widget that is stacked behind the child. If secondaryBackground is also
  /// specified then this widget only appears when the child has been dragged
  /// down or to the right.
  final Widget background;

  /// Called when the widget changes size (i.e., when contracting before being dismissed).
  final VoidCallback onResize;

  /// The direction in which the widget can be dismissed.
  final DismissDirection direction;

  /// Defines the duration for card to dismiss or to come back to original position if not dismissed.
  final Duration movementDuration;

  /// Defines the end offset across the main axis after the card is dismissed.
  ///
  /// If non-zero value is given then widget moves in cross direction depending on whether
  /// it is positive or negative.
  final double crossAxisEndOffset;

  @override
  _SlideActionsState createState() => _SlideActionsState();
}

class _DismissibleClipper extends CustomClipper<Rect> {
  _DismissibleClipper({
    @required this.axis,
    @required this.moveAnimation
  }) : assert(axis != null),
       assert(moveAnimation != null),
       super(reclip: moveAnimation);

  final Axis axis;
  final Animation<Offset> moveAnimation;

  @override
  Rect getClip(Size size) {
    assert(axis != null);
    switch (axis) {
      case Axis.horizontal:
        final double offset = moveAnimation.value.dx * size.width;
        if (offset < 0)
          return Rect.fromLTRB(size.width + offset, 0.0, size.width, size.height);
        return Rect.fromLTRB(0.0, 0.0, offset, size.height);
      case Axis.vertical:
        final double offset = moveAnimation.value.dy * size.height;
        if (offset < 0)
          return Rect.fromLTRB(0.0, size.height + offset, size.width, size.height);
        return Rect.fromLTRB(0.0, 0.0, size.width, offset);
    }
    return null;
  }

  @override
  Rect getApproximateClipRect(Size size) => getClip(size);

  @override
  bool shouldReclip(_DismissibleClipper oldClipper) {
    return oldClipper.axis != axis
        || oldClipper.moveAnimation.value != moveAnimation.value;
  }
}

enum _FlingGestureKind { none, forward, reverse }

class _SlideActionsState extends State<SlideActions> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin { // ignore: MIXIN_INFERENCE_INCONSISTENT_MATCHING_CLASSES
  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(duration: widget.movementDuration, vsync: this);
    _updateMoveAnimation();
  }

  AnimationController _moveController;
  Animation<Offset> _moveAnimation;

  AnimationController _resizeController;

  double _dragExtent = 0.0;
  bool _dragUnderway = false;

  @override
  bool get wantKeepAlive => _moveController?.isAnimating == true || _resizeController?.isAnimating == true;

  @override
  void dispose() {
    _moveController.dispose();
    _resizeController?.dispose();
    super.dispose();
  }


  DismissDirection _extentToDirection(double extent) {
    if (extent == 0.0) {
      return null;
    }
    switch (Directionality.of(context)) {
      case TextDirection.rtl:
        return extent < 0 ? DismissDirection.startToEnd : DismissDirection.endToStart;
      case TextDirection.ltr:
        return extent > 0 ? DismissDirection.startToEnd : DismissDirection.endToStart;
    }
    assert(false);
    return null;
  }

  DismissDirection get _dismissDirection => _extentToDirection(_dragExtent);

  bool get _isActive {
    return _dragUnderway || _moveController.isAnimating;
  }

  double get _overallDragAxisExtent {
    final Size size = context.size;
    return size.width / 4;
  }

  void _handleDragStart(DragStartDetails details) {
    _dragUnderway = true;
    if (_moveController.isAnimating) {
      _dragExtent = _moveController.value * _overallDragAxisExtent * _dragExtent.sign;
      _moveController.stop();
    } else if (_moveController.isDismissed) {
      _moveController.reverse();
    }
    setState(() {
      _updateMoveAnimation();
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isActive || _moveController.isAnimating)
      return;

    final double delta = details.primaryDelta;
    final double oldDragExtent = _dragExtent;
    switch (widget.direction) {
      case DismissDirection.horizontal:
      case DismissDirection.vertical:
        _dragExtent += delta;
        break;

      case DismissDirection.up:
        if (_dragExtent + delta < 0)
          _dragExtent += delta;
        break;

      case DismissDirection.down:
        if (_dragExtent + delta > 0)
          _dragExtent += delta;
        break;

      case DismissDirection.endToStart:
        switch (Directionality.of(context)) {
          case TextDirection.rtl:
            if (_dragExtent + delta > 0)
              _dragExtent += delta;
            break;
          case TextDirection.ltr:
            if (_dragExtent + delta < 0)
              _dragExtent += delta;
            break;
        }
        break;

      case DismissDirection.startToEnd:
        switch (Directionality.of(context)) {
          case TextDirection.rtl:
            if (_dragExtent + delta < 0)
              _dragExtent += delta;
            break;
          case TextDirection.ltr:
            if (_dragExtent + delta > 0)
              _dragExtent += delta;
            break;
        }
        break;
    }
    if (oldDragExtent.sign != _dragExtent.sign) {
      setState(() {
        _updateMoveAnimation();
      });
    }
    if (!_moveController.isAnimating) {
      _moveController.value = _dragExtent.abs() / _overallDragAxisExtent;
    }
  }

  void _updateMoveAnimation() {
    final double end = _dragExtent.sign;
    _moveAnimation = _moveController.drive(
      Tween<Offset>(
        begin: Offset.zero,
        end: Offset(end / 4, widget.crossAxisEndOffset),
      ),
    );
  }

  _FlingGestureKind _describeFlingGesture(Velocity velocity) {
    assert(widget.direction != null);
    if (_dragExtent == 0.0) {
      return _FlingGestureKind.none;
    }
    final double vx = velocity.pixelsPerSecond.dx;
    final double vy = velocity.pixelsPerSecond.dy;
    DismissDirection flingDirection;
    // Verify that the fling is in the generally right direction and fast enough.
    if (vx.abs() - vy.abs() < _kMinFlingVelocityDelta || vx.abs() < _kMinFlingVelocity) {
      return _FlingGestureKind.none;
    }
    assert(vx != 0.0);
    flingDirection = _extentToDirection(vx);
    assert(_dismissDirection != null);
    if (flingDirection == _dismissDirection)
      return _FlingGestureKind.forward;
    return _FlingGestureKind.reverse;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isActive || _moveController.isAnimating) {
      return;
    }
    _dragUnderway = false;
    if (_moveController.isCompleted) {
      return;
    }
    final double flingVelocity = details.velocity.pixelsPerSecond.dx;
    switch (_describeFlingGesture(details.velocity)) {
      case _FlingGestureKind.forward:
        assert(_dragExtent != 0.0);
        assert(!_moveController.isDismissed);
        if (_kDismissThreshold >= 1.0) {
          _moveController.reverse();
          break;
        }
        _dragExtent = flingVelocity.sign;
        _moveController.fling(velocity: flingVelocity.abs() * _kFlingVelocityScale);
        break;
      case _FlingGestureKind.reverse:
        assert(_dragExtent != 0.0);
        assert(!_moveController.isDismissed);
        _dragExtent = flingVelocity.sign;
        _moveController.fling(velocity: -flingVelocity.abs() * _kFlingVelocityScale);
        break;
      case _FlingGestureKind.none:
        if (!_moveController.isDismissed) { // we already know it's not completed, we check that above
          if (_moveController.value > _kDismissThreshold) {
            _moveController.forward();
          } else {
            _moveController.reverse();
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    Widget background = widget.background;
    Widget content = SlideTransition(
      position: _moveAnimation,
      child: widget.child
    );

    if (background != null) {
      final List<Widget> children = <Widget>[];
      if (!_moveAnimation.isDismissed) {
        children.add(Positioned.fill(
          child: ClipRect(
            clipper: _DismissibleClipper(
              axis: Axis.horizontal,
              moveAnimation: _moveAnimation,
            ),
            child: background
          )
        ));
      }
      children.add(content);
      content = Stack(children: children);
    }
    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      behavior: HitTestBehavior.opaque,
      child: content
    );
  }
}