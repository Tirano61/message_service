
import 'package:message_service/feactures/categories/domain/entity/category_entity.dart';

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getCategories(String token);
}

