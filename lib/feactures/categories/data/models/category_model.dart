

import 'dart:convert';

import 'package:message_service/feactures/categories/domain/entity/category_entity.dart';

List<CategoryModel> categoryModelFromJson(String str) => List<CategoryModel>.from(json.decode(str).map((x) => CategoryModel.fromJson(x)));

String categoryModelToJson(List<CategoryModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CategoryModel {
    final String? id;
    final String? name;
    final List<Component>? components;
    final String? description;
    final bool? isActive;
    final String? type;

    CategoryModel({
        this.id,
        this.name,
        this.components,
        this.description,
        this.isActive,
        this.type,
    });

    factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json["id"],
        name: json["name"],
        components: json["components"] == null ? [] : List<Component>.from(json["components"]!.map((x) => Component.fromJson(x))),
        description: json["description"],
        isActive: json["isActive"],
        type: json["type"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "components": components == null ? [] : List<dynamic>.from(components!.map((x) => x.toJson())),
        "description": description,
        "isActive": isActive,
        "type": type,
    };

    CategoryEntity toEntity() {
        return CategoryEntity(
            id: id,
            name: name,
            components: components,
            description: description,
            isActive: isActive,
            type: type,
        );
    } 
}

class Component {
    final String? id;
    final String? name;
    final String? description;

    Component({
        this.id,
        this.name,
        this.description,
    });

    factory Component.fromJson(Map<String, dynamic> json) => Component(
        id: json["id"],
        name: json["name"],
        description: json["description"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "description": description,
    };
}
