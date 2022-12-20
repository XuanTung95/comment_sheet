import 'package:comment_sheet/comment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final CommentSheetController commentSheetController =
      CommentSheetController();
  ScrollController scrollController = ScrollController();

  // This widget is the root of your application.

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
                              calculateTopPosition: (
                                CommentSheetInfo info,
                              ) {
                                if (info.currentTop < 500) {
                                  return 200;
                                }
                                return 600;
                              },
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
                                if (info.currentTop > 700) {
                                  Navigator.of(context).pop();
                                }
                              },
                              commentSheetController: commentSheetController,
                              child: const Placeholder(),
                            );
                          },
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

  Widget buildGrabbing(BuildContext context) {
    return Container(
      height: 120,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: EdgeInsets.only(top: 10, bottom: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: Colors.white60, borderRadius: BorderRadius.circular(100)),
          ),
          Container(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Text(
                    "Bình luận",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Text(
                    "48",
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
                Spacer(),
                Icon(
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
                    icon: Icon(
                      Icons.close,
                      size: 26,
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
          ),
          Container(
            color: Color(0xFF292929),
            width: double.infinity,
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget buildSliverList() {
    return SliverClip(
      child: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
        return ListItemWidget();
      }, childCount: 10)),
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
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
        },
        child: Container(
          color: Color(0xFF0F0F0F),
          width: double.infinity,
          padding: const EdgeInsets.only(top: 12, bottom: 0, left: 10, right: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 5, right: 10),
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
                    Text(
                      'Andrea Quintanilla * 3 tháng trước',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Color(0xFFAEAEAE)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 12),
                      child: Text(
                        'Que buen trabajo, que buenos enganches, genial!!!!  MTV la tenes adentro, jajaja. Saludos cordiales desde Buenos Aires, Argentina, Argentina, Argentina!',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFFF6F6F6)),
                      ),
                    ),
                    Row(children: [
                      Icon(Icons.thumb_up_outlined, size: 15, color: Colors.white,),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                        child: Icon(Icons.thumb_down_alt_outlined, size: 15, color: Colors.white,),
                      ),
                      Icon(Icons.comment_outlined, size: 15, color: Colors.white,),
                    ],)
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
