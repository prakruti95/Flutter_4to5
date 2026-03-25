import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/screens/post_list_screen.dart';
import 'presentation/viewmodels/post_view_model.dart';
import 'data/repositories/post_repository_impl.dart';
import 'data/datasources/remote/post_remote_data_source.dart';
import 'data/datasources/local/post_local_data_source.dart';
import 'domain/usecases/get_posts.dart';

void main()
{
  runApp(MyApp());
}
class MyApp extends StatelessWidget
{

  @override
  Widget build(BuildContext context)
  {
    return MultiProvider(providers:
    [
      Provider(create: (_) => PostRemoteDataSource()),
      Provider(create: (_) => PostLocalDataSource()),
      Provider
        (
        create: (context) => PostRepositoryImpl(
          remoteDataSource: context.read<PostRemoteDataSource>(),
          localDataSource: context.read<PostLocalDataSource>(),
        ),
      ),
      Provider(create: (context) => GetPosts(context.read<PostRepositoryImpl>())),

      ChangeNotifierProvider(
        create: (context) => PostViewModel(context.read<GetPosts>()),
      ),




    ],
      child: MaterialApp(
        title: 'Flutter Clean Architecture',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const PostListScreen(),
      ),);
  }
}
