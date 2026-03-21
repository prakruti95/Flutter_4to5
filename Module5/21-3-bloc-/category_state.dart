
import 'package:equatable/equatable.dart';
import 'category.dart';
import 'category_event.dart';

class CategoryRequested extends CategoryEvent {}

abstract class CategoryState extends Equatable
{
  @override
  List<Object?> get props => [];
}
class CategoryInitial extends CategoryState {}
class CategoryLoadSuccess extends CategoryState {
  final List<Category> categories;

  CategoryLoadSuccess({ required this.categories });

  @override
  List<Object?> get props => [categories];
}

class CategoryLoadFailure extends CategoryState {
  final String error;

  CategoryLoadFailure({ required this.error });

  @override
  List<Object?> get props => [error];
}
class CategoryLoadInProgress extends CategoryState {}