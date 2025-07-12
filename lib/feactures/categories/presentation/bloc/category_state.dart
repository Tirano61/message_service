part of 'category_bloc.dart';

@immutable
sealed class CategoryState {}

final class CategoryInitial extends CategoryState {}

final class CategoryLoadingState extends CategoryState {}

final class CategoryLoadedState extends CategoryState {
  final List<CategoryEntity> categoryEntity;

  CategoryLoadedState(this.categoryEntity);
}

final class CategoryErrorState extends CategoryState {
  final String message;

  CategoryErrorState(this.message);
}