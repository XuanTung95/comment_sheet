import 'package:comment_sheet/comment_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

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
      body: Stack(
        children: [
          const Placeholder(
            color: Colors.yellow,
          ),
          CommentSheet(
            slivers: [
              buildSliverList(),
            ],
            grabbingPosition: WidgetPosition.above,
            initTopPosition: 200,
            calculateTopPosition: calculateTopPosition,
            scrollController: scrollController,
            grabbing: Builder(builder: (context) {
              return buildGrabbing(context);
            }),
            topWidget: const Placeholder(
              color: Colors.green,
            ),
            topPosition: WidgetPosition.below,
            bottomWidget: buildBottomWidget(),
            onPointerUp: (
              BuildContext context,
              CommentSheetInfo info,
            ) {
              print("On Pointer Up");
            },
            onAnimationComplete: (
              BuildContext context,
              CommentSheetInfo info,
            ) {
              print("onAnimationComplete");
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
        ],
      ),
    );
  }

  double calculateTopPosition(
    CommentSheetInfo info,
  ) {
    final vy = info.velocity.getVelocity().pixelsPerSecond.dy;
    print("vy = $vy");
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
    }, childCount: 10));
  }
}
