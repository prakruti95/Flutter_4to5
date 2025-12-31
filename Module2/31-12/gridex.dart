import 'package:flutter/material.dart';

class GridEx extends StatefulWidget {
  const GridEx({super.key});

  @override
  State<GridEx> createState() => _GridExState();
}

class _GridExState extends State<GridEx>
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
          child: GridView.builder
            (
              itemCount: lan.length,
              itemBuilder:(context,index)
              {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 50,
                    color: Colors.green.shade500,
                    child: Center(
                        child: Text(lan[index],
                            style: TextStyle(fontSize: 20, color: Colors.white))),
                  ),
                );
              },
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount
              (
              crossAxisCount: 2, // 2 columns
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              ),
          )

      ),
    );
  }
}
