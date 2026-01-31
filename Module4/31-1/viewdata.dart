import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:untitled3/myjson/model.dart';
class ViewData extends StatefulWidget
{
  const ViewData({super.key});

  @override
  State<ViewData> createState() => _ViewDataState();
}

class _ViewDataState extends State<ViewData>
{
  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
        appBar: AppBar(title: Text("View Data"),),
        body: Center
          (
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
      );
  }

  getdata()async
  {
      var url = "https://simplifiedcoding.net/demos/marvel/";
      var resp = await http.get(Uri.parse(url));
      return jsonDecode(resp.body);
  }
}
