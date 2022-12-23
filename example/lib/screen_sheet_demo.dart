import 'dart:math';

import 'package:comment_sheet/comment_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'main.dart';

class ScreenSheetDemo extends StatefulWidget {
  const ScreenSheetDemo({Key? key}) : super(key: key);

  @override
  State<ScreenSheetDemo> createState() => _ScreenSheetDemoState();
}

class _ScreenSheetDemoState extends State<ScreenSheetDemo> {
  final scrollController = ScrollController();
  final commentSheetController = CommentSheetController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: CommentSheet(
        slivers: [
          buildSliverList(),
        ],
        grabbingPosition: WidgetPosition.above,
        initTopPosition: 200,
        calculateTopPosition: calculateTopPosition,
        onTopChanged: (top) {
          // print("top: $top");
        },
        scrollController: scrollController,
        grabbing: buildGrabbing(context),
        topWidget: (info) {
          return Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: max(0, info.currentTop),
            child: const Placeholder(
              color: Colors.green,
            ),
          );
        },
        topPosition: WidgetPosition.below,
        bottomWidget: buildBottomWidget(),
        onPointerUp: (
            BuildContext context,
            CommentSheetInfo info,
            ) {
          // print("On Pointer Up");
        },
        onAnimationComplete: (
            BuildContext context,
            CommentSheetInfo info,
            ) {
          // print("onAnimationComplete");
          if (info.currentTop >= info.size.maxHeight - 100) {
            Navigator.of(context).pop();
          }
        },
        commentSheetController: commentSheetController,
        child: const Placeholder(),
        backgroundBuilder: (context) {
          return Container(
            color: const Color(0xFF0F0F0F),
            margin: const EdgeInsets.only(top: 20),
          );
        },
      ),
    );
  }

  double calculateTopPosition(
    CommentSheetInfo info,
  ) {
    final vy = info.velocity.getVelocity().pixelsPerSecond.dy;
    // print("vy = $vy");
    final top = info.currentTop;
    if (top > 200) {
      if (vy > 0) {
        return info.size.maxHeight - 100;
      } else if (vy < -500) {
        return 0;
      }
      return 200;
    }
    if (top == 200) {
      return 200;
    } else if (top < 100) {
      if (top > 0 && vy > 100) {
        return 200;
      }
      return 0;
    } else {
      if (vy < -100) {
        return 0;
      }
    }
    return 200;
  }

  Container buildBottomWidget() {
    return Container(
      color: Colors.transparent,
      height: 50,
      child: const Placeholder(
        color: Colors.blue,
      ),
    );
  }

  Widget buildGrabbing(BuildContext context) {
    return const GrabbingWidget();
  }

  Widget buildSliverList() {
    return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
      return const ListItemWidget();
    }, childCount: 15));
  }
}
