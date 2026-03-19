import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'CounterCubit.dart';
import 'counterpage.dart';

void main()
{
  runApp(MyApp());
}
class MyApp extends StatelessWidget
{
  @override
  Widget build(BuildContext context)
  {
    return MaterialApp(
    home: BlocProvider(
          create: (_) => CounterCubit(),
          child: CounterPage(),
  ),
);
  }
}


