import 'dart:convert';

import 'package:http/http.dart' as http;

import 'category.dart';

class CategoryRepository
{
  final String _baseUrl = 'https://prakrutitech.xyz/FlutterProject/category_view.php';

  Future<List<Category>> fetchCategories() async
  {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200)
    {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Category.fromJson(json)).toList();
    }
    else
    {
      throw Exception('Failed to load categories');
    }
  }
}