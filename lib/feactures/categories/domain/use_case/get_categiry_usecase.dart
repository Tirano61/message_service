

import 'package:message_service/feactures/categories/domain/entity/category_entity.dart';
import 'package:message_service/feactures/categories/domain/repository/category_repository.dart';

class GetCategoriesUseCase  {

  final CategoryRepository categoryRepository;

  GetCategoriesUseCase({required this.categoryRepository});

  Future<List<CategoryEntity>> call(String token) async {
    return await categoryRepository.getCategories(token);
  }
}