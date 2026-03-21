import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'category_bloc.dart';
import 'category_repo.dart';
import 'category_state.dart';

class CategoryScreen extends StatefulWidget
{
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
{
  @override
  Widget build(BuildContext context)
  {
    return BlocProvider
      (
        create: (context) => CategoryBloc(repository: CategoryRepository())
          ..add(CategoryRequested()),
        child: Scaffold
          (
          appBar: AppBar(
            title: const Text('Categories'),
          ),
          body: BlocBuilder<CategoryBloc, CategoryState>(builder: (BuildContext context, CategoryState state)
          {
            if (state is CategoryLoadInProgress)
            {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CategoryLoadSuccess) {
              final categories = state.categories;
              return ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return ListTile(
                    title: Text(cat.categoryName!),
                    subtitle: Column
                      (
                      children:
                      [
                        Image.network(cat.categoryImg!),
                        Text(cat.id!)
                      ],
                    ),


                    // you can show other fields too
                  );
                },
              );
            }

            if (state is CategoryLoadFailure)
            {
              return Center(child: Text('Failed: ${state.error}'));
            }

            return const Center(child: Text('No data'));
          },
          ),
    ));

  }
}
