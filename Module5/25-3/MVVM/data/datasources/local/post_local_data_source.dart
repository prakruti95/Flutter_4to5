// data/datasources/local/post_local_data_source.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/post.dart';

class PostLocalDataSource
{
  Future<List<Post>> loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? postsJson = prefs.getStringList('posts');
    if (postsJson != null)
    {
      return postsJson.map((json) => Post.fromJson(jsonDecode(json))).toList();
    }
    else
    {
      return [];
    }
  }

  Future<void> savePosts(List<Post> posts) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> postsJson = posts.map((post) => jsonEncode(post.toJson())).toList();
    await prefs.setStringList('posts', postsJson);//save -sharedprefrence
  }
}
