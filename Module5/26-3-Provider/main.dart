import 'package:flutter/material.dart';
import 'package:myproviderex/theme_provider.dart';
import 'package:provider/provider.dart';

import 'counter.dart';
import 'mydata.dart';
import 'newapp.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp2(),
    ),
  );
}


// void main()
// {
//   runApp(ChangeNotifierProvider(create: (context) => CounterProvider(),child: MyApp()),);
// }
