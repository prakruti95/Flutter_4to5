import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jsoncrud1/add.dart';
import 'model.dart';

void main()
{
  runApp(MaterialApp(home: MyApp(),));
}
class MyApp extends StatefulWidget
{
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>
{
  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
        appBar: AppBar(),
        body: FutureBuilder
              (
                future: getdata(),
                builder:(context,snapshot)
                {
                    if(snapshot.hasError)
                    {
                          print("Network Error");
                    }
                    else if(snapshot.hasData)
                    {
                          return Model(list:snapshot.data);
                    }
                    return CircularProgressIndicator();

                }
              ),


        floatingActionButton: FloatingActionButton(onPressed: ()
        {
          Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => AddData()));
        },child: Icon((Icons.add)),),
      );
  }

  getdata()async
  {
    var url = "https://prakrutitech.xyz/Seminar/view.php";
    var resp = await http.get(Uri.parse(url));
    return jsonDecode(resp.body);
  }
}
