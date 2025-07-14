


import 'package:message_service/feactures/categories/data/models/category_model.dart';

class CategoryEntity {
  final String? id;
  final String? name;
  final List<Component>? components;
  final String? description;
  final bool? isActive;
  final String? type;
 

  CategoryEntity({
    required this.id,
    required this.name,
    required this.components,
    required this.description,
    required this.isActive,
    required this.type,
  });

  
}