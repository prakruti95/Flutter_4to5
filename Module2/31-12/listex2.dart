import 'package:flutter/material.dart';

class ListEx2 extends StatefulWidget {
  const ListEx2({super.key});

  @override
  State<ListEx2> createState() => _ListEx2State();
}

class _ListEx2State extends State<ListEx2>
{

  List lan =
  [
      "java",
      "php",
      "python",
      "c#",
    "java",
    "php",
    "python",
    "c#",
    "java",
    "php",
    "python",
    "c#",
    "java",
    "php",
    "python",
    "c#"
  ];

  List logo =
  [
    "assets/a.png",
    "assets/a.png",
    "assets/a.png",
    "assets/a.png",
    "assets/a.png",
    "assets/a.png",
    "assets/a.png",
    "assets/a.png",
    "assets/a.png",
    "assets/a.png",
    "assets/a.png",
    "assets/a.png",
    "assets/a.png",
    "assets/a.png",
    "assets/a.png",
    "assets/a.png",

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold
      (
        appBar: AppBar(),
        body: Center
          (
            child: ListView.builder
              (
                itemCount: lan.length,
                itemBuilder:(context,index)
                {
                    return ListTile
                      (
                          leading: Image.asset(logo[index]),
                          title: Text(lan[index]),
                      );
                }
              )

          ),
      );
  }
}
