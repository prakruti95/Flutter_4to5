import 'dart:convert';

import '../../../domain/entities/post.dart';
import 'package:http/http.dart' as http;
class PostRemoteDataSource
{
  final String apiUrl = 'https://jsonplaceholder.typicode.com/posts';

  Future<List<Post>> fetchPosts() async
  {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200)
    {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Post.fromJson(json)).toList();
    }
    else
    {
      throw Exception('Failed to load posts');
    }
  }
}