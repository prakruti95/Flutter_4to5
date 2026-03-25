// data/repositories/post_repository_impl.dart
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/local/post_local_data_source.dart';
import '../datasources/remote/post_remote_data_source.dart';

class PostRepositoryImpl implements PostRepository
{
  final PostRemoteDataSource remoteDataSource;
  final PostLocalDataSource localDataSource;

  PostRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<Post>> getPosts() async
  {
    // Check if there are posts in local storage
    List<Post> localPosts = await localDataSource.loadPosts();

    if (localPosts.isNotEmpty)
    {
      return localPosts;
    }
    else
    {
      // Fetch from API
      List<Post> remotePosts = await remoteDataSource.fetchPosts();
      // Save to local storage
      localDataSource.savePosts(remotePosts);
      return remotePosts;
    }
  }
}
