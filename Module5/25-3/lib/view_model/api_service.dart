import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user_model.dart';

class APIService {
  static const String apiUrl = 'https://prakrutitech.xyz/Autosync/view.php';
  static const String insertApi = 'https://prakrutitech.xyz/Autosync/insert.php';

  static Future<List<UserModel>> fetchData() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load data');
    }
  }

  static Future<bool> insertData(UserModel user) async {
    try {
      final response = await http.post(
        Uri.parse(insertApi),
        body: {
          'id': user.id.toString(),
          'name': user.name,
          'email': user.email,
          'password': user.password,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Insert Error: $e');
      return false;
    }
  }
}
