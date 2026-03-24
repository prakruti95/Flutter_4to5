import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'api_Service.dart';

class ConnectivityHelper
{

  static Future<bool> isOnline() async
  {
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult.contains(ConnectivityResult.none))
    {
      return false;
    }

    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    }
    catch (_)
    {
      return false;
    }

    return false;
  }

  static void monitorConnectivity() {
    Connectivity().checkConnectivity().then((result) async {
      if (await isOnline())
      {
        await APIService.syncOfflineData();
      }
    });

    Connectivity().onConnectivityChanged.listen((result) async {
      if (await isOnline()) {
        await APIService.syncOfflineData();
      }
    });
  }


}