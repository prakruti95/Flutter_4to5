import 'package:flutter/material.dart';

class MyTabView extends StatefulWidget {
  const MyTabView({super.key});

  @override
  State<MyTabView> createState() => _MyTabViewState();
}

class _MyTabViewState extends State<MyTabView> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController
      (
          length: 3,
          child: Scaffold
            (
              appBar: AppBar
                (
                  bottom: TabBar(tabs:
                  [
                    Tab(icon: Icon(Icons.directions_car)),
                    Tab(icon: Icon(Icons.directions_transit)),
                    Tab(icon: Icon(Icons.directions_bike)),

                  ]),
                  title: const Text('Tabs Demo'),
                ),

            body:  TabBarView(
              children: [
                Icon(Icons.directions_car),
                Icon(Icons.directions_transit),
                Icon(Icons.directions_bike),
              ],
            ),

            )
      );

  }
}
