part of 'category_bloc.dart';

@immutable
sealed class CategoryEvent {}

final class CategoryLoadEvent extends CategoryEvent {}

final class CategoryAddEvent extends CategoryEvent {
  final String name;

  CategoryAddEvent(this.name);
}

final class CategoryComponentsEvent extends CategoryEvent {
  final CategoryEntity categoryEntity;

  CategoryComponentsEvent(this.categoryEntity);
}