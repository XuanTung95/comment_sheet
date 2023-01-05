import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import 'comment_sheet_controller.dart';

enum WidgetPosition { below, above }

class CommentSheet extends StatefulWidget {
  const CommentSheet({
    Key? key,
    required this.child,
    required this.grabbing,
    required this.slivers,
    required this.calculateTopPosition,
    required this.commentSheetController,
    this.initTopPosition = 0,
    this.scrollController,
    this.topWidget,
    this.bottomWidget,
    this.topPosition = WidgetPosition.below,
    this.grabbingPosition = WidgetPosition.below,
    this.onPointerUp,
    this.onPointerDown,
    this.onPointerCancel,
    this.backgroundBuilder,
    this.simulationBuilder = CommentSheetState.buildSimulation,
    this.scrollPhysics = const CommentSheetBouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics()),
    this.onAnimationComplete,
    this.clipBehavior = Clip.hardEdge,
    this.onTopChanged,
  }) : super(key: key);

  final Widget? child;
  final Widget? grabbing;
  final Widget Function(CommentSheetInfo info)? topWidget;
  final double initTopPosition;
  final WidgetPosition topPosition;
  final Widget? bottomWidget;
  final WidgetPosition grabbingPosition;
  final List<Widget> slivers;
  final ScrollController? scrollController;
  final CommentSheetController commentSheetController;
  final WidgetBuilder? backgroundBuilder;
  final double Function(CommentSheetInfo info) calculateTopPosition;

  final void Function(BuildContext context, CommentSheetInfo info)? onPointerUp;
  final void Function(BuildContext context, CommentSheetInfo info)? onPointerCancel;
  final void Function()? onPointerDown;

  final void Function(BuildContext state, CommentSheetInfo info)?
      onAnimationComplete;

  final ScrollPhysics scrollPhysics;

  final Simulation Function(double target, CommentSheetInfo info)
      simulationBuilder;

  final Clip clipBehavior;

  final void Function(double top)? onTopChanged;

  @override
  State<CommentSheet> createState() => CommentSheetState();
}

class CommentSheetInfo {
  final BoxConstraints size;
  final VelocityTracker velocity;
  final double currentTop;
  final ScrollController scrollController;

  const CommentSheetInfo({
    required this.size,
    required this.velocity,
    required this.currentTop,
    required this.scrollController,
  });
}

class CommentSheetState extends State<CommentSheet>
    with SingleTickerProviderStateMixin {
  late ScrollController scrollController;
  late CommentSheetController commentSheetController;
  late AnimationController animationController;
  late final bool _createdScrollController;

  double _top = 0; // from top of stack -> top of the grabbing
  double _scrollOffset = 0; // scrollController.offset when offset < 0

  BoxConstraints _size = BoxConstraints.tight(Size.zero);

  BoxConstraints get size => _size;

  final VelocityTracker _vt = VelocityTracker.withKind(PointerDeviceKind.touch);

  VelocityTracker get velocityTracker => _vt;

  double get fakeTop => _top - _scrollOffset;

  @override
  void initState() {
    super.initState();
    _setCommentSheetController();
    _top = widget.initTopPosition;
    scrollController = widget.scrollController ?? ScrollController();
    _createdScrollController = widget.scrollController == null;
    scrollController.addListener(_scrollControllerListener);

    animationController = AnimationController.unbounded(vsync: this);
    animationController.addListener(() {
      setState(() {
        _top = animationController.value;
        widget.onTopChanged?.call(fakeTop);
      });
    });
  }

  void _setCommentSheetController() {
    commentSheetController = widget.commentSheetController;
    commentSheetController.state = this;
  }

  void _scrollControllerListener() {
    if (scrollController.offset <= 0) {
      setState(() {
        _scrollOffset = scrollController.offset;
        widget.onTopChanged?.call(fakeTop);
      });
    } else {
      // scrollOffset should be 0
      if (_scrollOffset != 0) {
        setState(() {
          _scrollOffset = 0;
          widget.onTopChanged?.call(fakeTop);
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant CommentSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setCommentSheetController();
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollControllerListener);
    commentSheetController.state = null;
    animationController.dispose();
    if (_createdScrollController) {
      scrollController.dispose();
    }
    super.dispose();
  }

  TickerFuture animateToPosition(double target) {
    var simulation = widget.simulationBuilder.call(target, getInfo(_size));
    final ret = animationController.animateWith(simulation);
    if (widget.onAnimationComplete != null) {
      ret.whenComplete(() {
        widget.onAnimationComplete?.call(context, getInfo(_size));
      });
    }
    return ret;
  }

  static Simulation buildSimulation(double target, CommentSheetInfo info) {
    return StopBouncingScrollSimulation(
      spring: SpringDescription.withDampingRatio(
        mass: 0.5,
        stiffness: 200.0,
        ratio: 1.1,
      ),
      position: info.currentTop,
      velocity: 0,
      // velocity: info.velocity.getVelocity().pixelsPerSecond.dy,
      leadingExtent: target,
      trailingExtent: target,
      tolerance: Tolerance.defaultTolerance,
    );
  }

  void _resetTopToCurrentScrollOffset() {
    if (_scrollOffset < 0) {
      _top = _top - _scrollOffset;
      scrollController.jumpTo(0);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, size) {
      _size = size;
      final info = getInfo(size);
      Widget? widgetTop =
          widget.topWidget == null ? null : widget.topWidget!.call(info);

      return Stack(
        clipBehavior: widget.clipBehavior,
        children: [
          if (widget.child != null) RepaintBoundary(
            child: widget.child!
          ),
          if (widget.topPosition == WidgetPosition.below && widgetTop != null)
            widgetTop,
          if (widget.backgroundBuilder != null)
            Positioned(
              top: fakeTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: widget.backgroundBuilder!.call(context),
            ),
          Positioned(
            top: _top,
            left: 0,
            right: 0,
            bottom: 0,
            child: Listener(
              onPointerDown: (PointerDownEvent p) {
                _vt.addPosition(p.timeStamp, p.position);
                widget.onPointerDown?.call();
              },
              onPointerMove: (detail) {
                _vt.addPosition(detail.timeStamp, detail.position);
              },
              onPointerCancel: (detail) {
                _resetTopToCurrentScrollOffset();
                final info = getInfo(size);
                widget.onPointerCancel?.call(
                  context,
                  info,
                );
              },
              onPointerUp: (detail) {
                _resetTopToCurrentScrollOffset();
                final info = getInfo(size);
                widget.onPointerUp?.call(
                  context,
                  info,
                );
                animateToPosition(widget.calculateTopPosition(
                  info,
                ));
              },
              child: (widget.grabbingPosition == WidgetPosition.below ||
                      widget.grabbing == null)
                  ? Column(children: [
                      if (widget.grabbing != null) buildGrabber(),
                      _buildScrollView(),
                      if (widget.bottomWidget != null) widget.bottomWidget!,
                    ])
                  : Stack(
                      children: [
                        Column(children: [
                          if (widget.grabbing != null)
                            Opacity(opacity: 0, child: widget.grabbing),
                          _buildScrollView(),
                          if (widget.bottomWidget != null) widget.bottomWidget!,
                        ]),
                        buildGrabber(),
                      ],
                    ),
            ),
          ),
          if (widget.topPosition == WidgetPosition.above && widgetTop != null)
            widgetTop,
        ],
      );
    });
  }

  CommentSheetInfo getInfo(BoxConstraints size) {
    return CommentSheetInfo(
      velocity: _vt,
      size: size,
      currentTop: fakeTop,
      scrollController: scrollController,
    );
  }

  Widget buildGrabber() {
    if (widget.grabbing == null) {
      return const SizedBox();
    }
    return Transform.translate(
      offset: Offset(0, -_scrollOffset),
      child: GestureDetector(
        onVerticalDragUpdate: (detail) {
          setState(() {
            _top = _top + detail.delta.dy;
            widget.onTopChanged?.call(fakeTop);
          });
        },
        onPanDown: (detail) {
          if (animationController.isAnimating) {
            animationController.stop();
          }
        },
        child: widget.grabbing!,
      ),
    );
  }

  Widget _buildScrollView() {
    return Expanded(
      child: CustomScrollView(
        controller: scrollController,
        physics: widget.scrollPhysics,
        slivers: widget.slivers,
      ),
    );
  }
}

class CommentSheetBouncingScrollPhysics extends ScrollPhysics {
  /// Creates scroll physics that bounce back from the edge.
  const CommentSheetBouncingScrollPhysics({ScrollPhysics? parent})
      : super(parent: parent);

  @override
  CommentSheetBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CommentSheetBouncingScrollPhysics(
      parent: buildParent(ancestor),
    );
  }

  /// The multiple applied to overscroll to make it appear that scrolling past
  /// the edge of the scrollable contents is harder than scrolling the list.
  /// This is done by reducing the ratio of the scroll effect output vs the
  /// scroll gesture input.
  ///
  /// This factor starts at 0.52 and progressively becomes harder to overscroll
  /// as more of the area past the edge is dragged in (represented by an increasing
  /// `overscrollFraction` which starts at 0 when there is no overscroll).
  double frictionFactor(double overscrollFraction) =>
      0.52 * math.pow(1 - overscrollFraction, 2);

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    assert(offset != 0.0);
    assert(position.minScrollExtent <= position.maxScrollExtent);

    if (!position.outOfRange) {
      return offset;
    }
    if (position.pixels <= 0) {
      return offset;
    }

    final double overscrollPastStart =
        math.max(position.minScrollExtent - position.pixels, 0.0);
    final double overscrollPastEnd =
        math.max(position.pixels - position.maxScrollExtent, 0.0);
    final double overscrollPast =
        math.max(overscrollPastStart, overscrollPastEnd);
    final bool easing = (overscrollPastStart > 0.0 && offset < 0.0) ||
        (overscrollPastEnd > 0.0 && offset > 0.0);

    final double friction = easing
        // Apply less resistance when easing the overscroll vs tensioning.
        ? frictionFactor(
            (overscrollPast - offset.abs()) / position.viewportDimension)
        : frictionFactor(overscrollPast / position.viewportDimension);
    final double direction = offset.sign;

    return direction * _applyFriction(overscrollPast, offset.abs(), friction);
  }

  static double _applyFriction(
      double extentOutside, double absDelta, double gamma) {
    assert(absDelta > 0);
    double total = 0.0;
    if (extentOutside > 0) {
      final double deltaToLimit = extentOutside / gamma;
      if (absDelta < deltaToLimit) {
        return absDelta * gamma;
      }
      total += extentOutside;
      absDelta -= deltaToLimit;
    }
    return total + absDelta;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) => 0.0;

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final Tolerance tolerance = this.tolerance;
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      return StopBouncingScrollSimulation(
        spring: spring,
        position: position.pixels,
        velocity: velocity,
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        tolerance: tolerance,
      );
    }
    // return null to begin an idle activity
    return null;
  }

  // The ballistic simulation here decelerates more slowly than the one for
  // ClampingScrollPhysics so we require a more deliberate input gesture
  // to trigger a fling.
  @override
  double get minFlingVelocity => kMinFlingVelocity * 2.0;

  // Methodology:
  // 1- Use https://github.com/flutter/platform_tests/tree/master/scroll_overlay to test with
  //    Flutter and platform scroll views superimposed.
  // 3- If the scrollables stopped overlapping at any moment, adjust the desired
  //    output value of this function at that input speed.
  // 4- Feed new input/output set into a power curve fitter. Change function
  //    and repeat from 2.
  // 5- Repeat from 2 with medium and slow flings.
  /// Momentum build-up function that mimics iOS's scroll speed increase with repeated flings.
  ///
  /// The velocity of the last fling is not an important factor. Existing speed
  /// and (related) time since last fling are factors for the velocity transfer
  /// calculations.
  @override
  double carriedMomentum(double existingVelocity) {
    return existingVelocity.sign *
        math.min(0.000816 * math.pow(existingVelocity.abs(), 1.967).toDouble(),
            40000.0);
  }

  // Eyeballed from observation to counter the effect of an unintended scroll
  // from the natural motion of lifting the finger after a scroll.
  @override
  double get dragStartDistanceMotionThreshold => 3.5;
}

class StopBouncingScrollSimulation extends Simulation {
  /// Creates a simulation group for scrolling on iOS, with the given
  /// parameters.
  ///
  /// The position and velocity arguments must use the same units as will be
  /// expected from the [x] and [dx] methods respectively (typically logical
  /// pixels and logical pixels per second respectively).
  ///
  /// The leading and trailing extents must use the unit of length, the same
  /// unit as used for the position argument and as expected from the [x]
  /// method (typically logical pixels).
  ///
  /// The units used with the provided [SpringDescription] must similarly be
  /// consistent with the other arguments. A default set of constants is used
  /// for the `spring` description if it is omitted; these defaults assume
  /// that the unit of length is the logical pixel.
  StopBouncingScrollSimulation({
    required double position,
    required double velocity,
    required this.leadingExtent,
    required this.trailingExtent,
    required this.spring,
    required Tolerance tolerance,
  }) : assert(position != null),
        assert(velocity != null),
        assert(leadingExtent != null),
        assert(trailingExtent != null),
        assert(leadingExtent <= trailingExtent),
        assert(spring != null),
        super(tolerance: tolerance) {
    if (position < leadingExtent) {
      _springSimulation = _underscrollSimulation(position, velocity);
      _springTime = double.negativeInfinity;
    } else if (position > trailingExtent) {
      _springSimulation = _overscrollSimulation(position, velocity);
      _springTime = double.negativeInfinity;
    } else {
      // Taken from UIScrollView.decelerationRate (.normal = 0.998)
      // 0.998^1000 = ~0.135
      _frictionSimulation = FrictionSimulation(0.135, position, velocity);
      final double finalX = _frictionSimulation.finalX;
      if (velocity > 0.0 && finalX > trailingExtent) {
        _springTime = _frictionSimulation.timeAtX(trailingExtent);
        _springSimulation = StopSimulation(
          trailingExtent,
        );
        assert(_springTime.isFinite);
      } else if (velocity < 0.0 && finalX < leadingExtent) {
        _springTime = _frictionSimulation.timeAtX(leadingExtent);
        _springSimulation = StopSimulation(
          leadingExtent,
        );
        assert(_springTime.isFinite);
      } else {
        _springTime = double.infinity;
      }
    }
    assert(_springTime != null);
  }

  /// The maximum velocity that can be transferred from the inertia of a ballistic
  /// scroll into overscroll.
  static const double maxSpringTransferVelocity = 5000.0;

  /// When [x] falls below this value the simulation switches from an internal friction
  /// model to a spring model which causes [x] to "spring" back to [leadingExtent].
  final double leadingExtent;

  /// When [x] exceeds this value the simulation switches from an internal friction
  /// model to a spring model which causes [x] to "spring" back to [trailingExtent].
  final double trailingExtent;

  /// The spring used to return [x] to either [leadingExtent] or [trailingExtent].
  final SpringDescription spring;

  late FrictionSimulation _frictionSimulation;
  late Simulation _springSimulation;
  late double _springTime;
  double _timeOffset = 0.0;

  Simulation _underscrollSimulation(double x, double dx) {
    return ScrollSpringSimulation(spring, x, leadingExtent, dx);
  }

  Simulation _overscrollSimulation(double x, double dx) {
    return ScrollSpringSimulation(spring, x, trailingExtent, dx);
  }

  Simulation _simulation(double time) {
    final Simulation simulation;
    if (time > _springTime) {
      _timeOffset = _springTime.isFinite ? _springTime : 0.0;
      simulation = _springSimulation;
    } else {
      _timeOffset = 0.0;
      simulation = _frictionSimulation;
    }
    return simulation..tolerance = tolerance;
  }

  @override
  double x(double time) => _simulation(time).x(time - _timeOffset);

  @override
  double dx(double time) => _simulation(time).dx(time - _timeOffset);

  @override
  bool isDone(double time) => _simulation(time).isDone(time - _timeOffset);

  @override
  String toString() {
    return '${objectRuntimeType(this, 'BouncingScrollSimulation')}(leadingExtent: $leadingExtent, trailingExtent: $trailingExtent)';
  }
}


class StopSimulation extends Simulation {
  final double stop;

  StopSimulation(this.stop);

  @override
  double dx(double time) {
    return 0;
  }

  @override
  bool isDone(double time) {
    return true;
  }

  @override
  double x(double time) {
    return stop;
  }

}