
import 'package:flutter/material.dart';
import 'package:message_service/feactures/categories/domain/entity/category_entity.dart';

class ComponentPage extends StatefulWidget {
  final CategoryEntity categoryEntity;
  const ComponentPage({super.key, required this.categoryEntity});

  @override
  State<ComponentPage> createState() => _ComponentPageState();
}

class _ComponentPageState extends State<ComponentPage> {


  @override
  Widget build(BuildContext context) {
    final components = widget.categoryEntity.components; // Asegúrate de que exista esta propiedad

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryEntity.name ?? ''), // Asumiendo que CategoryEntity tiene 'name'
      ),
      body: ListView.builder(
        itemCount: components!.length,
        itemBuilder: (context, index) {
          final component = components[index];
          return ListTile(
            title: Text(component.name ?? ''), // Asumiendo que ComponentEntity tiene 'name'
            subtitle: Text(component.description ?? ''), // Si tiene descripción
            // Puedes agregar más información aquí
          );
        },
      ),
    );
  }
}