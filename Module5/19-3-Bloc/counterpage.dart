import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'CounterCubit.dart';

class CounterPage extends StatefulWidget
{
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage>
{
  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
        appBar: AppBar(title: Text("Counter App"),),
        body: BlocBuilder<CounterCubit, int>(builder: (context,count)
        {
            return Center(child: Text('$count'));
        }),
      floatingActionButton: Column
        (
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
          children:
          [
            FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () => context.read<CounterCubit>().increment(),
            ),

            const SizedBox(height: 4),

            FloatingActionButton(
              child: const Icon(Icons.remove),
              onPressed: () => context.read<CounterCubit>().decrement(),
            ),


          ],
        ),
      );

  }
}
