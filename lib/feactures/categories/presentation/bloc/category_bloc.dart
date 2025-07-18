import 'package:bloc/bloc.dart';
import 'package:message_service/feactures/auth/domain/entities/user.dart';
import 'package:message_service/feactures/categories/data/datasourse/category_remote_datasourse.dart';
import 'package:message_service/feactures/categories/domain/entity/category_entity.dart';
import 'package:message_service/feactures/categories/domain/use_case/get_categiry_usecase.dart';
import 'package:meta/meta.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {

  final GetCategoriesUseCase getCategoriesUseCase;
  final UserEntity userEntity;

  CategoryBloc({required this.getCategoriesUseCase, required this.userEntity}) : super(CategoryInitial()) {
    on<CategoryLoadEvent>((event, emit)async {
      emit(CategoryLoadingState());
      try {

        final categories = await getCategoriesUseCase(userEntity.token);

        emit(CategoryLoadedState(categoryEntity: categories));
      } catch (error) {
        emit(CategoryErrorState(message: error.toString()));
      }
    });

    on<CategoryComponentsEvent>((event, emit) async {
      emit(CategoryComponentsLoadingState());
      
    });
  }
}
