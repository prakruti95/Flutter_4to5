import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jsoncrud1/add.dart';
import 'package:jsoncrud1/signin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model.dart';

void main() {
  runApp(const MaterialApp(home: Signin()));
}

class MyApp extends StatefulWidget 
{
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>
{
  late SharedPreferences sharedPreferences;
  String myuser = "";



  late Future<dynamic> futureData;

  List mainList = [];
  List filteredList = [];

  @override
  void initState() {
    checkdata();
    futureData = getdata();
    super.initState();
  }

  Future<void> _refreshData() async {
    setState(() {
      futureData = getdata();
    });
  }

  void searchData(String value)
  {
    setState(() {
      filteredList = mainList.where((element) {
        return element["pname"]
            .toString()
            .toLowerCase()
            .contains(value.toLowerCase());
      }).toList();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product List"),
        actions: 
        [
          IconButton(onPressed: ()
          {
            sharedPreferences.setBool("tops", true);
            Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => Signin()));
          }, icon: Icon(Icons.logout))
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Column(
          children: [

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: searchData,
                decoration: InputDecoration(
                  hintText: "Search product...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),


            Expanded(
              child: FutureBuilder(
                future: futureData,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Network Error"));
                  }

                  if (snapshot.hasData)
                  {
                    mainList = snapshot.data;
                    filteredList = filteredList.isEmpty
                        ? mainList
                        : filteredList;

                    return Model(list: filteredList);
                  }

                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AddData()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<dynamic> getdata() async {
    var url = "https://prakrutitech.xyz/Seminar/view.php";
    var resp = await http.get(Uri.parse(url));
    return jsonDecode(resp.body);
  }

  checkdata() async
  {
      sharedPreferences = await SharedPreferences.getInstance();

      setState(()
      {
        myuser = sharedPreferences.getString("email")!;
      });
  }
}
