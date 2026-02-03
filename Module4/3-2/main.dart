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
  late Future<dynamic> futureData;

  @override
  void initState()
  {

    futureData = getdata(); // initial API call
  }

  Future<void> _refreshData() async
  {

    setState(() {
      futureData = getdata(); // reload API
    });
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
        appBar: AppBar(),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: FutureBuilder
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
        ),




        floatingActionButton: FloatingActionButton(onPressed: ()
        {
          Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => AddData()));
        },child: Icon((Icons.add)),),
      );
  }

  Future<dynamic>getdata()async
  {
    var url = "https://prakrutitech.xyz/Seminar/view.php";
    var resp = await http.get(Uri.parse(url));
    return jsonDecode(resp.body);
  }
}
