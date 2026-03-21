import 'package:flutter_bloc/flutter_bloc.dart';

import 'category_event.dart';
import 'category_repo.dart';
import 'category_state.dart';


class CategoryBloc extends Bloc<CategoryEvent, CategoryState>
{
  final CategoryRepository repository;

  CategoryBloc({ required this.repository }) : super(CategoryInitial()) {
    on<CategoryRequested>((event, emit) async
    {
      emit(CategoryLoadInProgress());
      try
      {
        final categories = await repository.fetchCategories();
        emit(CategoryLoadSuccess(categories: categories));
      } catch (e) {
        emit(CategoryLoadFailure(error: e.toString()));
      }
    });
  }

}