import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../view_model/connectivity_helper.dart';
import '../view_model/user_view_model.dart';


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _viewModel = UserViewModel();
  List<UserModel> users = [];

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ConnectivityHelper.monitorConnectivity();
    loadData();
  }

  Future<void> loadData() async {
    final data = await _viewModel.loadUsers();
    setState(() {
      users = data;
    });
  }

  Future<void> addUser() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch,
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    await _viewModel.addUser(newUser);
    await loadData();

    _nameController.clear();

    _emailController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Offline Sync (MVVM)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Name')),
            TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            SizedBox(height: 16),
            ElevatedButton(onPressed: addUser, child: Text('Add User')),
            ElevatedButton(onPressed: loadData, child: Text('Refresh')),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(users[i].name),
                  subtitle: Text(users[i].email),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}