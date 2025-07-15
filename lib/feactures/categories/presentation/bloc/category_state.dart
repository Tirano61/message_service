part of 'category_bloc.dart';

@immutable
sealed class CategoryState {}

final class CategoryInitial extends CategoryState {}

final class CategoryLoadingState extends CategoryState {}

final class CategoryLoadedState extends CategoryState {
  final List<CategoryEntity> categoryEntity;

  CategoryLoadedState({required this.categoryEntity});
}

final class CategoryErrorState extends CategoryState {
  final String message;

  CategoryErrorState({required this.message});
}

final class CategoryComponentsLoadingState extends CategoryState {}

final class CategoryComponentsState extends CategoryState {
  final CategoryEntity categoryEntity;

  CategoryComponentsState({required this.categoryEntity});
}
