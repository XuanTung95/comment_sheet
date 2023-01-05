import 'dart:math';

import 'package:comment_sheet/comment_sheet.dart';
import 'package:example/screen_sheet_demo.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final CommentSheetController commentSheetController =
      CommentSheetController();
  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Builder(builder: (context) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              LoadingCupertinoSliverRefreshControl(
                onRefresh: () async {
                  await Future.delayed(const Duration(seconds: 3));
                },
              ),
              SliverFillRemaining(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ListTile(
                      title: const Text("Open Sheet"),
                      onTap: () {
                        showBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) {
                            return CommentSheet(
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
                                if (info.currentTop >=
                                    info.size.maxHeight - 100) {
                                  Navigator.of(context).pop();
                                }
                              },
                              commentSheetController: commentSheetController,
                              onTopChanged: (top) {
                                // print("top: $top");
                              },
                              child: const Placeholder(),
                              backgroundBuilder: (context) {
                                return Container(
                                  color: const Color(0xFF0F0F0F),
                                  margin: const EdgeInsets.only(top: 20),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    ListTile(
                      title: const Text("Show Sheet in Stack"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return const ScreenSheetDemo();
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )
            ],
          );
        }),
      ),
    );
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

  double calculateTopPosition(
    CommentSheetInfo info,
  ) {
    final vy = info.velocity.getVelocity().pixelsPerSecond.dy;
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

  Widget buildGrabbing(BuildContext context) {
    return const GrabbingWidget();
  }

  Widget buildSliverList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return const ListItemWidget();
      }, childCount: 20),
    );
  }
}

class GrabbingWidget extends StatelessWidget {
  const GrabbingWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
                color: Colors.white60,
                borderRadius: BorderRadius.circular(100)),
          ),
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 15),
                child: Text(
                  "Bình luận",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 6.0),
                child: Text(
                  "48",
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.menu_sharp,
                size: 26,
                color: Colors.white,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0, right: 10),
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.close,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
          Container(
            color: const Color(0xFF292929),
            width: double.infinity,
            height: 1,
          ),
        ],
      ),
    );
  }
}

class ListItemWidget extends StatelessWidget {
  const ListItemWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0F0F0F),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
        },
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.only(top: 12, bottom: 0, left: 10, right: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 5, right: 10),
                child: ClipOval(
                        child: Image.network(
                          "https://yt3.ggpht.com/yti/AJo0G0kUnHqoybmWPJG4GNm0G-lfCiCPbEP62v5tq9PZsA=s48-c-k-c0x00ffffff-no-rj",
                          width: 25,
                          height: 25,
                        ),
                      ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Andrea Quintanilla * 3 tháng trước',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFAEAEAE)),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 6, bottom: 12),
                      child: Text(
                        'Que buen trabajo, que buenos enganches, genial!!!!  MTV la tenes adentro, jajaja. Saludos cordiales desde Buenos Aires, Argentina, Argentina, Argentina!',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFF6F6F6)),
                      ),
                    ),
                    Row(
                      children: const [
                        Icon(
                          Icons.thumb_up_outlined,
                          size: 15,
                          color: Colors.white,
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 16.0, right: 16.0),
                          child: Icon(
                            Icons.thumb_down_alt_outlined,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                        Icon(
                          Icons.comment_outlined,
                          size: 15,
                          color: Colors.white,
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
