import '../models/entity/user_model.dart';
import '../models/localdata/db_helper.dart';
import 'api_service.dart';

class UserViewModel {
  Future<List<UserModel>> loadUsers() async {
    List<UserModel> users = [];
    try {
      final onlineData = await APIService.fetchData();
      await DBHelper.clearTable();
      for (var user in onlineData) {
        user.isSynced = 1;
        await DBHelper.insertUser(user);
      }
    } catch (_) {}
    users = await DBHelper.fetchUsers();
    return users.where((user) => user.isSynced == 1).toList();
  }

  Future<void> addUser(UserModel user) async {
    bool online = true;
    try {
      online = await APIService.insertData(user);
    } catch (_) {
      online = false;
    }

    user.isSynced = online ? 1 : 0;
    await DBHelper.insertUser(user);
  }

  Future<void> syncOfflineData() async {
    final users = await DBHelper.fetchUsers();
    for (var user in users.where((u) => u.isSynced == 0)) {
      final success = await APIService.insertData(user);
      if (success) {
        user.isSynced = 1;
        await DBHelper.updateUser(user);
      }
    }
  }
}
