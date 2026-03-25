import 'package:connectivity_plus/connectivity_plus.dart';
import 'user_view_model.dart';

class ConnectivityHelper {
  static Future<bool> isOnline() async {
    var result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static Future<void> monitorConnectivity() async {
    final viewModel = UserViewModel();
    Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        await viewModel.syncOfflineData();
      }
    });
  }
}
