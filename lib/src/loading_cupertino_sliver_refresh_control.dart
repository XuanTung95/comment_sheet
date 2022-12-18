
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LoadingCupertinoSliverRefreshControl extends StatelessWidget {
  const LoadingCupertinoSliverRefreshControl({Key? key,
    this.refreshTriggerPullDistance = 100,
    this.refreshIndicatorExtent = 60,
    this.builder = buildRefreshIndicator,
    this.onRefresh,}) : super(key: key);

  final double refreshTriggerPullDistance;

  final double refreshIndicatorExtent;

  final RefreshControlIndicatorBuilder? builder;

  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverRefreshControl(
        onRefresh: onRefresh,
        refreshTriggerPullDistance: refreshTriggerPullDistance,
        refreshIndicatorExtent: refreshIndicatorExtent,
        builder: builder);
  }

  static Widget buildRefreshIndicator(
      BuildContext context,
      RefreshIndicatorMode refreshState,
      double pulledExtent,
      double refreshTriggerPullDistance,
      double refreshIndicatorExtent,
      ) {
    final double percentageComplete =
    clampDouble(pulledExtent / refreshTriggerPullDistance, 0.0, 1.0);

    // Place the indicator at the top of the sliver that opens up. Note that we're using
    // a Stack/Positioned widget because the CupertinoActivityIndicator does some internal
    // translations based on the current size (which grows as the user drags) that makes
    // Padding calculations difficult. Rather than be reliant on the internal implementation
    // of the activity indicator, the Positioned widget allows us to be explicit where the
    // widget gets placed. Also note that the indicator should appear over the top of the
    // dragged widget, hence the use of Overflow.visible.
    const Curve topCurve = Interval(0.0, 1.0, curve: Curves.easeInOut);
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            Positioned(
              top: -40 + topCurve.transform(percentageComplete) * 60,
              child: _buildIndicatorForRefreshState(
                  refreshState, 50, percentageComplete),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildIndicatorForRefreshState(
      RefreshIndicatorMode refreshState,
      double radius,
      double percentageComplete) {
    const backgroundColor = Colors.white;
    const double strokeWidth = 2;
    switch (refreshState) {
      case RefreshIndicatorMode.drag:
      // While we're dragging, we draw individual ticks of the spinner while simultaneously
      // easing the opacity in. Note that the opacity curve values here were derived using
      // Xcode through inspecting a native app running on iOS 13.5.
        if (percentageComplete < 0.1) {
          return const SizedBox();
        }

        Widget child = RefreshProgressIndicator(
          value: percentageComplete,
          valueColor: null,
          backgroundColor: backgroundColor,
          strokeWidth: strokeWidth,
        );
        return child;
      case RefreshIndicatorMode.armed:
      case RefreshIndicatorMode.refresh:
      // Once we're armed or performing the refresh, we just show the normal spinner.
        return const RefreshProgressIndicator(
          value: null,
          valueColor: null,
          backgroundColor: backgroundColor,
          strokeWidth: strokeWidth,
        );
      case RefreshIndicatorMode.done:
        Widget child = const RefreshProgressIndicator(
          value: null,
          valueColor: null,
          backgroundColor: backgroundColor,
          strokeWidth: strokeWidth,
        );
        return child;
      case RefreshIndicatorMode.inactive:
      // Anything else doesn't show anything.
        return Container();
    }
  }
}
