import 'package:bloc/bloc.dart';
import 'package:message_service/feactures/categories/domain/entity/category_entity.dart';
import 'package:meta/meta.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc() : super(CategoryInitial()) {
    on<CategoryEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
