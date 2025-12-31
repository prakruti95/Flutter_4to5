import 'package:flutter/material.dart';

class ListEx extends StatefulWidget {
  const ListEx({super.key});

  @override
  State<ListEx> createState() => _ListExState();
}

class _ListExState extends State<ListEx> {
  @override
  Widget build(BuildContext context) {
    return Scaffold
      (
        appBar: AppBar(),
        body: Center
          (
            child: ListView
              (
                children:
                [
                    ListTile
                      (
                          title: Text("Abhay"),

                      ),
                    ListTile
                      (
                      title: Text("Baldev"),
                    ),
                  ListTile
                    (
                    title: Text("Sweni"),
                  ),
                  ListTile
                    (
                    title: Text("Diya"),
                  ),
                  ListTile
                    (
                    title: Image.asset("assets/a.png",width: 200,height: 200,),
                  )

                ],
              ),
          ),
      );
  }
}
