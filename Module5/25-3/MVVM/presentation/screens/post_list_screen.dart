import 'package:day10mvvm/presentation/viewmodels/post_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PostListScreen extends StatelessWidget
{
  const PostListScreen({super.key});

  @override
  Widget build(BuildContext context)
  {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostViewModel>(context, listen: false).fetchPosts();
    });

    return Scaffold
      (
        appBar: AppBar(title: Text("Posts"),),
        body: Consumer<PostViewModel>(builder: (context, value,  child)
        {

          if (value.isLoading)
          {
            return const Center(child: CircularProgressIndicator());
          }
          if (value.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value.errorMessage),
                  ElevatedButton(
                    onPressed: () => value.retry(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

            return ListView.builder
              (
                itemCount: 5,
                itemBuilder: (context,index)
                {
                  final post = value.posts[index];
                    return ListTile
                      (
                        title:Text(post.title!),
                        subtitle:Text(post.body!),
                      );
                }
              );

        },)




      );
  }
}
