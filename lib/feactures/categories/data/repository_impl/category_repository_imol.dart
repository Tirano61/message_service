

import 'package:message_service/feactures/categories/data/datasourse/category_remote_datasourse.dart';
import 'package:message_service/feactures/categories/domain/entity/category_entity.dart';
import 'package:message_service/feactures/categories/domain/repository/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource categoryRemoteDataSource;

  CategoryRepositoryImpl({required this.categoryRemoteDataSource});

  @override
  Future<List<CategoryEntity>> getCategories(String token) async {

    final resp =  await categoryRemoteDataSource.getAllCategories(token);
    if (resp.isNotEmpty) {
      return resp.map((model) => model.toEntity()).toList();
    }
    
    return [];
  }
}