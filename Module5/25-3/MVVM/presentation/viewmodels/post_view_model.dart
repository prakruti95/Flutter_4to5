// presentation/viewmodels/post_view_model.dart

import 'package:flutter/material.dart';

import '../../domain/entities/post.dart';
import '../../domain/usecases/get_posts.dart';

class PostViewModel extends ChangeNotifier
{
  final GetPosts getPosts;

  PostViewModel(this.getPosts);

  List<Post> _posts = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Fetch posts using the GetPosts use case
  // Future<void> fetchPosts() async {
  //   _isLoading = true;
  //   _errorMessage = '';
  //   notifyListeners();
  //
  //   try {
  //     _posts = await getPosts.execute();
  //   } catch (e) {
  //     _errorMessage = 'Failed to load posts';
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  // In PostViewModel
  Future<void> fetchPosts() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _posts = await getPosts.execute();
    } catch (e) {
      print("Error fetching posts: $e");  // Log the error
      _errorMessage = 'Failed to load posts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to handle retry after an error
  Future<void> retry() async {
    await fetchPosts();
  }
}
