import 'package:comment_sheet/comment_sheet.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

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

  Stack buildGrabbing(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 5)],
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10), topRight: Radius.circular(10))),
          height: 100,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.close)),
        ),
      ],
    );
  }

  SliverList buildSliverList() {
    return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
      return Material(
        color: Colors.amberAccent.shade100,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Container(
            height: 100,
            // color: Colors.amberAccent.shade100,
            width: double.infinity,
            child: Center(
              child: Text("Item: $index"),
            ),
          ),
        ),
      );
    }, childCount: 10));
  }
}
