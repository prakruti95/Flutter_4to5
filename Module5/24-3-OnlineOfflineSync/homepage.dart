import 'package:flutter/material.dart';

import 'api_Service.dart';
import 'connectivity_helper.dart';
import 'dbhelper.dart';

class HomePage extends StatefulWidget
{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
{
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    // TODO: implement initState
    ConnectivityHelper.monitorConnectivity();
    loadData();
  }
  Future<void> loadData() async {
    bool online = await ConnectivityHelper.isOnline();

    if (online) {
      // Fetch data from API only if online
      final data = await APIService.fetchData();
      await DBHelper.clearTable(); // Clear previous data to avoid duplicates
      for (var user in data) {
        await DBHelper.insertUser({
          'id': user['id'],
          'name': user['name'],
          'email': user['email'],
          'password': user['password'],
          'isSynced': 1
        });
      }
    }

    final localData = await DBHelper.fetchUsers();
    setState(() {
      users = localData.where((user) => user['isSynced'] == 1).toList();
    });
  }

  Future<void> addUser() async {
    final newUser = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'name': 'User ${DateTime.now().millisecondsSinceEpoch}',
      'email': 'user@example.com',
      'password': 'password123',
    };

    bool online = await ConnectivityHelper.isOnline();

    if (online) {
      bool success = await APIService.insertData(newUser);
      if (success) {
        await DBHelper.insertUser({
          ...newUser,
          'isSynced': 1,
        });
      }
    } else {
      await DBHelper.insertUser({
        ...newUser,
        'isSynced': 0,
      });
    }

    loadData();
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
        appBar: AppBar(title: Text("App"),),
        body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(users[index]['name']),
            subtitle: Text(users[index]['email']),
          );
        },
      ),
        floatingActionButton: FloatingActionButton(onPressed: ()
        {
          addUser();

        },child: Icon(Icons.add),),
      );
  }
}
