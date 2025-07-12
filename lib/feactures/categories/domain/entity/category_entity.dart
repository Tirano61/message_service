


class CategoryEntity {
  final String id;
  final String name;
 

  CategoryEntity({
    required this.id,
    required this.name,
});

  @override
  String toString() {
    return 'CategoryEntity(id: $id, name: $name)';
  }
}