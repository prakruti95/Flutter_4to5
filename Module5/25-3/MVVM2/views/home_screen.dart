import 'package:flutter/material.dart';

import '../models/entity/user_model.dart';
import '../view_models/connectivity_helper.dart';
import '../view_models/user_view_model.dart';

class HomeScreen extends StatefulWidget
{
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
{
  final _viewModel = UserViewModel();
  List<UserModel> users = [];


  TextEditingController _nameController = TextEditingController();
  TextEditingController _surnameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  Future<void> loadData() async {
    final data = await _viewModel.loadUsers();
    setState(() {
      users = data;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    ConnectivityHelper.monitorConnectivity();
    loadData();
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
        appBar: AppBar(title: Text("MVVM"),),
        body: Center
          (
            child: Column
              (
                children:
                [

                  TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Name')),
                  TextField(controller: _surnameController, decoration: InputDecoration(labelText: 'Surname')),
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

  Future<void> addUser() async {
    if (_nameController.text.isEmpty ||
        _surnameController.text.isEmpty ||
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
      surname: _surnameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    await _viewModel.addUser(newUser);
    await loadData();

    _nameController.clear();
    _surnameController.clear();
    _emailController.clear();
    _passwordController.clear();
  }

}
