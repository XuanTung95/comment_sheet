
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
    this.topPosition = WidgetPosition.above,
    this.grabbingPosition = WidgetPosition.above,
    this.onPointerUp,
    this.backgroundBuilder,
    this.simulationBuilder = CommentSheetState.buildSimulation,
    this.scrollPhysics = const CommentSheetBouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics()),
    this.onAnimationComplete,
  }) : super(key: key);

  final Widget child;
  final Widget? grabbing;
  final Widget? topWidget;
  final double initTopPosition;
  final WidgetPosition topPosition;
  final Widget? bottomWidget;
  final WidgetPosition grabbingPosition;
  final List<Widget> slivers;
  final ScrollController? scrollController;
  final CommentSheetController commentSheetController;
  final WidgetBuilder? backgroundBuilder;
  final double Function(
    CommentSheetInfo info,
  ) calculateTopPosition;

  final void Function(
    BuildContext context,
    CommentSheetInfo info,
  )? onPointerUp;

  final void Function(
      BuildContext state,
      CommentSheetInfo info,
      )? onAnimationComplete;

  final ScrollPhysics scrollPhysics;

  final Simulation Function(double target, CommentSheetInfo info)
      simulationBuilder;

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

  double top = 0; // from top of stack -> top of the grabbing
  double _scrollOffset = 0; // scrollController.offset when offset < 0

  BoxConstraints _size = BoxConstraints.tight(Size.zero);
  final VelocityTracker _vt = VelocityTracker.withKind(PointerDeviceKind.touch);

  VelocityTracker get velocityTracker => _vt;

  double get fakeTop {
    return top - _scrollOffset;
  }

  @override
  void initState() {
    super.initState();
    setCommentSheetController();
    top = widget.initTopPosition;
    scrollController = widget.scrollController ?? ScrollController();
    scrollController.addListener(scrollControllerListener);

    animationController = AnimationController.unbounded(vsync: this);
    animationController.addListener(() {
      setState(() {
        top = animationController.value;
      });
    });
  }

  void setCommentSheetController() {
    commentSheetController = widget.commentSheetController;
    commentSheetController.state = this;
  }

  void scrollControllerListener() {
    if (scrollController.offset <= 0) {
      setState(() {
        _scrollOffset = scrollController.offset;
      });
    } else {
      // scrollOffset should be 0
      if (_scrollOffset != 0) {
        setState(() {
          _scrollOffset = 0;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant CommentSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    setCommentSheetController();
  }

  @override
  void dispose() {
    scrollController.removeListener(scrollControllerListener);
    commentSheetController.state = null;
    animationController.dispose();
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
    return BouncingScrollSimulation(
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
      tolerance: Tolerance(
        velocity:
            1.0 / (0.050 * WidgetsBinding.instance.window.devicePixelRatio),
        // logical pixels per second
        distance: 1.0 / WidgetsBinding.instance.window.devicePixelRatio,
        // logical pixels
      ),
    );
  }

  void resetTopToCurrentScrollOffset() {
    if (_scrollOffset < 0) {
      top = top - _scrollOffset;
      scrollController.jumpTo(0);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, size) {
      _size = size;
      Widget? widgetTop = widget.topWidget == null
          ? null
          : Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: math.max(0, top - _scrollOffset),
              child: widget.topWidget!);

      return Stack(
        children: [
          if (widget.topPosition == WidgetPosition.below &&
              widget.topWidget != null)
            widgetTop!,
          if (widget.backgroundBuilder != null)
            Positioned(
              top: top - _scrollOffset,
              left: 0,
              right: 0,
              bottom: 0,
            child: widget.backgroundBuilder!.call(context),
          ),
          Positioned(
            top: top,
            left: 0,
            right: 0,
            bottom: 0,
            child: Listener(
              onPointerDown: (PointerDownEvent p) =>
                  _vt.addPosition(p.timeStamp, p.position),
              onPointerMove: (detail) {
                _vt.addPosition(detail.timeStamp, detail.position);
              },
              onPointerUp: (detail) {
                resetTopToCurrentScrollOffset();
                final info = getInfo(size);
                widget.onPointerUp?.call(
                  context,
                  info,
                );
                animateToPosition(widget.calculateTopPosition(
                  info,
                ));
              },
              child: widget.grabbingPosition == WidgetPosition.below
                  ? Column(children: [
                    if (widget.grabbing != null) buildGrabber(),
                      buildScrollView(),
                      if (widget.bottomWidget != null) widget.bottomWidget!,
                    ])
                  : Stack(
                      children: [
                        Column(children: [
                          if (widget.grabbing != null)
                            Opacity(opacity: 0, child: widget.grabbing),
                          buildScrollView(),
                          if (widget.bottomWidget != null) widget.bottomWidget!,
                        ]),
                        buildGrabber(),
                      ],
                    ),
            ),
          ),
          if (widget.topPosition == WidgetPosition.above &&
              widget.topWidget != null)
            widgetTop!,
        ],
      );
    });
  }

  CommentSheetInfo getInfo(BoxConstraints size) {
    return CommentSheetInfo(
      velocity: _vt,
      size: size,
      currentTop: top,
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
            top = top + detail.delta.dy;
          });
        },
        child: widget.grabbing!,
      ),
    );
  }

  Widget buildScrollView() {
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
      return BouncingScrollSimulation(
        spring: spring,
        position: position.pixels,
        velocity: velocity,
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        tolerance: tolerance,
      );
    }
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