
import 'dart:convert';

import 'package:message_service/feactures/categories/data/models/category_model.dart';
import 'package:http/http.dart' as http;

abstract class CategoryRemoteDataSource {

  Future<List<CategoryModel>> getAllCategories(String token);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  
  @override
  Future<List<CategoryModel>> getAllCategories(String token) async {
    final uri = Uri.parse('http://10.0.2.2:3000/category'); // Corrige la URL

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener las categorías');
    }
  }

}